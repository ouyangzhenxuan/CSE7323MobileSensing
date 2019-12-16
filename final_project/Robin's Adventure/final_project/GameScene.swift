//
//  GameScene.swift
//  final_project
//
//  Created by Yu Chen on 11/8/19.
//  Copyright © 2019 5323. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion
import CoreML
import UIKit

// delegate the predict_action() to other class
protocol ActionDelegate {
    func actionBegin()
    func actionDone()
    func updatePredictedAction()
    func getPredictedAction() -> String
}

protocol ActionHttpDelegate {
    func actionBegin()
    func actionDone()
    func updatePredictedAction()
    func getPredictedAction() -> String
    func prepareUrl()
}

protocol GameViewControllerDelegate: class {
    func finishGame(inputProperty:String)
}

// gamescene that manages entire game
class GameScene: SKScene,ControlInputDelegate,SKPhysicsContactDelegate{
    // initial variables
    
    var dev = false
    var isPauseMenu = false
    var gameViewControllerDelegate:GameViewControllerDelegate?
    var pause:Bool = false
    var left:Bool = false
    var right:Bool = false
    var jump: Bool = false
    var orientation: Int = 1
    var nextStep:Int = 0
    var stepCount:Int = 0
    var inventory1: SKSpriteNode?
    var textbox: SKSpriteNode?
    var stop1: SKSpriteNode?
    var stop2: SKSpriteNode?
    var stop3: SKSpriteNode?
    var stop4: SKSpriteNode?
    
    var stop5: SKSpriteNode?
    var stop6: SKSpriteNode?
    var stop7: SKSpriteNode?
    var stop8: SKSpriteNode?
    
    var stop9: SKSpriteNode?
    var stop10: SKSpriteNode?
    var stop11: SKSpriteNode?
    var stop12: SKSpriteNode?
    
    var textlabel: SKLabelNode?
    var shipGone:Bool = false
    var player_speed: CGFloat = 100
    
    // initial sprite nodes
    var player: SKSpriteNode?
    var lao: SKSpriteNode?
    var sun: SKSpriteNode?
    var uncle: SKSpriteNode?
    var ninja: SKSpriteNode?
    var ninja_destination: SKSpriteNode?
    var label : SKLabelNode?
    var touchControlNode : TouchInputNode?
    var face_left: Bool = true
    var face_right: Bool = false
    
    var lao_end: SKSpriteNode?
    var sun_end: SKSpriteNode?
    var naked_end: SKSpriteNode?
    var ninja_end: SKSpriteNode?
    var priest_end: SKSpriteNode?
    var doctor_end: SKSpriteNode?
    var doctor2_end: SKSpriteNode?
    
    
    // MARK: Machine Learning part
//    let theAction = ActionPredict.sharedInstance
    let theAction = HttpPredictController.sharedInstance

    // MARK: Button Control Functions
    func follow(command: String?) {
        // pause menu
        switch command {
        case "pause":
            print("pause pressed")
            self.pause = true
            self.touchControlNode?.pauseMenuPopUp()
        case "resume":
            print("resume pressed")
            self.pause = false
            self.touchControlNode?.pauseMenuDisappear()

        case "exit":
            self.touchControlNode?.pauseMenuDisappear()
            self.backToMenu()
            print("exit pressed")
        default:
            print("....")
        }
        
        if(self.pause&&self.dev==false){
            return
        }
        switch (command!){
        case ("left"):
            self.face_left = true
            self.face_right = false
            scene?.view?.isPaused = false
            self.textlabel?.isHidden=true
            self.textbox?.isHidden=true
            self.left = true
            self.right = false
            self.orientation = -1
        case ("right"):
            self.face_left = false
            self.face_right = true
            scene?.view?.isPaused = false
            self.textlabel?.isHidden=true
            self.textbox?.isHidden=true
            self.right = true
            self.left = false
            self.orientation = 1
        // jump function
        case ("A"):
            self.actionJump()
        // machine learning button to identify actions
        case ("B"):
            theAction.actionBegin()
            DispatchQueue.main.asyncAfter(deadline: .now()+1.5, execute: {
                print("delay 1.5s : \(self.theAction.getPredictedAction())")
                
                if(self.theAction.getPredictedAction() == "['droppingdown']"){
                    self.eatItem()
                }else if(self.theAction.getPredictedAction() == "['throwing']"){
                    self.throwItem()
                }else if(self.theAction.getPredictedAction() == "['pickingup']"){
                    self.actionPickup()
                }
                
            })
        case "stop right":
            
            self.player?.texture = SKTexture(imageNamed: "robin")
            self.right = false
            self.left = false
        case "stop left":
            self.player?.texture = SKTexture(imageNamed: "robin_back")
            self.left = false
            self.right = false
        // buttons to use inventory
        case "inventory1_item":
            self.touchControlNode?.selectInventory(inve_name: "inventory1_item")
        case "inventory2_item":
            self.touchControlNode?.selectInventory(inve_name: "inventory2_item")
        case "inventory3_item":
            self.touchControlNode?.selectInventory(inve_name: "inventory3_item")
        case "inventory4_item":
            self.touchControlNode?.selectInventory(inve_name: "inventory4_item")
        case "inventory5_item":
            self.touchControlNode?.selectInventory(inve_name: "inventory5_item")
        case "inventory6_item":
            self.touchControlNode?.selectInventory(inve_name: "inventory6_item")
        case "T": // temporarily set as exit button
            self.throwItem()
        case "M":   // pick up function
            self.actionPickup()
        default:
            print("Button: \(String(describing: command))")
        }
    }
    
    func backToMenu() {
            /* 1) Grab reference to our SpriteKit view */
            guard let skView = self.view as SKView? else {
                print("Could not get Skview")
                return
            }
            
            /* 2) Load Game scene */
            guard let scene = MainMenu(fileNamed:"MainMenu") else {
                print("Could not make GameScene, check the name is spelled correctly")
                return
            }
            
            /* 3) Ensure correct aspect mode */
            scene.scaleMode = .aspectFill
            
            skView.ignoresSiblingOrder = true
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            /* 4) Start game scene */
    //        skView.presentScene(scene)
            skView.presentScene(scene, transition: SKTransition.fade(withDuration: 1))
        }
    
    // MARK: JUMP Function
    // start the jump action one time
    func actionJump(){
        if let player = self.player {
            if(abs((player.physicsBody?.velocity.dy)!) < 10){
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 250))
            }
        }
    }
    
    // MARK: Throw Function
    // function to throw items that have category 3
    func throwItem(){
        
        if(self.touchControlNode?.checkItemCategory()==3 || self.touchControlNode?.checkItemCategory()==21){
            if let item = self.touchControlNode?.useItem(){
                item.physicsBody?.allowsRotation=false
                item.physicsBody?.affectedByGravity=true
                item.physicsBody?.restitution = 0
                item.physicsBody?.categoryBitMask=3
                item.physicsBody?.collisionBitMask=3
                //                item?.physicsBody?.pinned=true
                item.position.x = (self.player?.position.x)! + CGFloat(self.orientation*6)
                item.position.y = (self.player?.position.y)! + 24
                item.physicsBody?.velocity.dx = CGFloat(self.orientation * 200)
                item.physicsBody?.friction=1
                item.physicsBody?.mass = 1
                if(enter_way){
                    item.lightingBitMask = 1
                }
                
                self.addChild(item)
            }
        }
    }
    
    // MARK: EAT Function
    // function to eat items that have category 2
    // once palyer eat item, he will get speeded up
    func eatItem(){
        if(self.touchControlNode?.checkItemCategory()==2){
            if let item = self.touchControlNode?.useItem(){
                let up = SKLabelNode(text: "Speed Up!")
                up.fontSize = 10
                up.fontName = "AvenirNext-Bold"
                up.fontColor = .yellow
                up.position.x = (self.player?.position.x)!
                up.position.y = (self.player?.position.y)!+17
                self.addChild(up)
                up.run(SKAction.moveTo(y: (up.position.y)+10, duration: 1))
                up.run(SKAction.fadeOut(withDuration: 1))
                
                let speedup = SKAction.run {
                    self.player_speed = 200
                }
                let duration = TimeInterval(10)
                let duration_action = SKAction.wait(forDuration: duration)
                let done = SKAction.run{
                    self.player_speed = 100
                }
                self.player?.run(SKAction.sequence([speedup,duration_action,done]))
            }
        }
    }
    
    // MARK: Pickup Function
    // start the pickup action
    // player will pick up nearest pickable item
    func actionPickup(){
        print("hahaha \(self.theAction.getPredictedAction())")
        var nearest = 99999
        var nearnode: SKSpriteNode? = nil
        
        // Uncle and Ninja part
        
        for node in self.children{
            
            if(node.physicsBody?.categoryBitMask==2||node.physicsBody?.categoryBitMask==3||node.physicsBody?.categoryBitMask==21){
                
                let dis = abs((self.player?.position.x)! - node.position.x)+abs((self.player?.position.y)! - node.position.y)
                if Int(dis) < nearest{
                    nearest = Int(dis)
                    nearnode = node as? SKSpriteNode
                }
            }
            
        }
        
        if(nearnode?.name != nil&&nearest<40){
            if(nearnode?.name == "Ninja"){
                if(self.pickupNinja()==false){
                    return
                }
            }
            
            if((touchControlNode?.setinventory(tex: nearnode!.texture!, category:nearnode!.physicsBody!.categoryBitMask,name:nearnode!.name!))!){
                callText(text: "You Pick Up the "+((nearnode?.name!)!))
                nearnode?.removeFromParent()}
        }
    }
    
    func pickupNinja()->Bool{
        if self.finishedUncle == true{
            return false
        }
        self.ninjaHealed = self.isNinjaHealed()
        print(self.ninjaHealed)
        if self.ninjaHealed == false{
            callText(text: "I need some water and mushrooms...")
            return false
        }
        self.stop5?.removeFromParent()
        self.stop6?.removeFromParent()
        self.stop7?.removeFromParent()
        self.stop8?.removeFromParent()
//        self.ninjaEatFood()
        self.player_speed = 100
        self.ninja?.texture = SKTexture.init(imageNamed: "ninja_left")
        return true
    }
    
    // MARK: Didmove Function
    override func didMove(to view: SKView) {
        //set up game world with initial pyhsics and camera
        physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        setupControls(camera: camera!, scene: self)
        //
        self.theAction.prepareUrl()
        // set up main player
        self.player = childNode(withName: "Robin") as? SKSpriteNode
        self.player?.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 16, height: 30))
        self.player?.physicsBody?.allowsRotation = false
        self.player?.physicsBody?.categoryBitMask = 1
        self.player?.physicsBody?.collisionBitMask = 1
        self.player?.physicsBody?.contactTestBitMask = 1
        self.player?.physicsBody?.affectedByGravity = true
        self.player?.physicsBody?.mass = 1
        self.player?.physicsBody?.friction = 1
        
        // set up text which will pop up when pick up an item
        self.textbox = camera?.childNode(withName: "Textbox") as? SKSpriteNode
        self.textlabel = camera?.childNode(withName: "Textlabel") as? SKLabelNode
        self.textbox?.isHidden=true
        self.textlabel?.isHidden=true
        self.textbox?.zPosition=13
        self.textlabel?.zPosition=14
        
        self.lao = childNode(withName: "Lao") as? SKSpriteNode
        self.sun = childNode(withName: "sun") as? SKSpriteNode
        self.stop1 = childNode(withName: "stop1") as? SKSpriteNode
        self.stop2 = childNode(withName: "stop2") as? SKSpriteNode
        self.stop3 = childNode(withName: "stop3") as? SKSpriteNode
        self.stop4 = childNode(withName: "stop4") as? SKSpriteNode
        
        self.uncle = childNode(withName: "Uncle") as? SKSpriteNode
        self.ninja = childNode(withName: "Ninja") as? SKSpriteNode
        self.ninja_destination = childNode(withName: "ninja_destination") as? SKSpriteNode
        
        self.stop5 = childNode(withName: "stop5") as? SKSpriteNode
        self.stop6 = childNode(withName: "stop6") as? SKSpriteNode
        self.stop7 = childNode(withName: "stop7") as? SKSpriteNode
        self.stop8 = childNode(withName: "stop8") as? SKSpriteNode
        
        self.stop9 = childNode(withName: "stop9") as? SKSpriteNode
        self.stop10 = childNode(withName: "stop10") as? SKSpriteNode
        self.stop11 = childNode(withName: "stop11") as? SKSpriteNode
        self.stop12 = childNode(withName: "stop12") as? SKSpriteNode
        
        
        self.naked_end = childNode(withName: "naked_end") as? SKSpriteNode
        self.doctor_end = childNode(withName: "doctor_end") as? SKSpriteNode
        self.doctor2_end = childNode(withName: "doctor2_end") as? SKSpriteNode
        self.sun_end = childNode(withName: "sun_end") as? SKSpriteNode
        self.lao_end = childNode(withName: "lao_end") as? SKSpriteNode
        self.ninja_end = childNode(withName: "ninja_end") as? SKSpriteNode
        self.priest_end = childNode(withName: "priest_end") as? SKSpriteNode
        
        let naked_jump = SKAction.applyImpulse(CGVector(dx: 0, dy: 50), at: naked_end!.anchorPoint, duration: 2.8)
        let ninja_jump = SKAction.applyImpulse(CGVector(dx: 0, dy: 50), at: ninja_end!.anchorPoint, duration: 2.8)
        let sun_jump = SKAction.applyImpulse(CGVector(dx: 0, dy: 50), at: sun_end!.anchorPoint, duration: 2.8)
        let doctor_jump = SKAction.applyImpulse(CGVector(dx: 0, dy: 50), at: doctor_end!.anchorPoint, duration: 2.8)
        let doctor2_jump = SKAction.applyImpulse(CGVector(dx: 0, dy: 50), at: doctor2_end!.anchorPoint, duration: 2.8)
        let priest_jump = SKAction.applyImpulse(CGVector(dx: 0, dy: 50), at: priest_end!.anchorPoint, duration: 2.8)
        let lao_jump = SKAction.applyImpulse(CGVector(dx: 0, dy: 50), at: lao_end!.anchorPoint, duration: 2.8)
        let duration_action = SKAction.wait(forDuration: 0.1)
        let naked_action = SKAction.repeatForever(SKAction.sequence([naked_jump,duration_action]))
        let ninja_action = SKAction.repeatForever(SKAction.sequence([duration_action,ninja_jump]))
        let sun_action = SKAction.repeatForever(SKAction.sequence([sun_jump,duration_action]))
        let priest_action = SKAction.repeatForever(SKAction.sequence([duration_action,priest_jump]))
        let doctor_action = SKAction.repeatForever(SKAction.sequence([doctor_jump,duration_action]))
        let doctor2_action = SKAction.repeatForever(SKAction.sequence([duration_action,doctor2_jump]))
        let lao_action = SKAction.repeatForever(SKAction.sequence([lao_jump,duration_action]))
        naked_end?.run(naked_action)
        ninja_end?.run(ninja_action)
        doctor2_end?.run(doctor2_action)
        doctor_end?.run(doctor_action)
        lao_end?.run(lao_action)
        priest_end?.run(priest_action)
        sun_end?.run(sun_action)
        if(!self.dev){
            callIntroText()
        }
    }
    
    // once pick up an item, show tedt on the screen
    func setupText(camera : SKCameraNode, scene: SKScene,text:String) {
        
        touchControlNode = TouchInputNode(frame: scene.frame)
        touchControlNode?.inputDelegate = self
        touchControlNode?.position = CGPoint.zero
        
        
        camera.addChild(touchControlNode!)
    }
    
    // MARK: 关卡设计
    let introText = [
        "Robin: What is this place?",
        "Robin: Anyone here?",
        "Robin: ....",
        "Robin: Calm down, I have been to worse"]
    var introIndex = 0
    var introFinished = false
    func callIntroText(){
        callText(text: introText[0])
    }
    var prev_velocity = 100
    
    
    var laoIndex = 0
    var startedLao = false
    var finishedLao = false
    var conversationLao = false
    let laoText = [
        "Lao: Hey there?",
        "Robin: Oh hello? Do you know...",
        "Lao: What's your name?",
        "Robin: Robin",
        "Lao: Bob? My grandson",
        "Robin: No. Robin, I am Robin",
        "Lao: Young Bob, can you climb the tree and get my snowman back?",
        "Robin: I'm Ro... Whatever..."
        ]
    func missionLao(){
        if(finishedLao){
            callText(text: "Lao: Thank you, Bob...")
        }else{
            if(!startedLao){
                startedLao = true
                callText(text: laoText[0])
            }
        }
    }
    
    let SunText = [
        "Sun: Buenas tardes, señor, ¿puede traerme hierba?",
        "Robin: Such a weird island.",
        "Sun: ¿Qué?",
        "Robin: hierba?",
        "Sun: sí",
        "Robin: Oh, herb! All right"
        ]
    var SunIndex = 0
    var startedSun = false
    var finishedSun = false
    var conversationSun = false
    func missionSun(){
        if(finishedSun){
            callText(text: "Sun: Gracias!")
        }else{
            if(!startedSun){
                startedSun = true
                callText(text: SunText[0])
            }
        }
    }
    
    var mission_priest = false;
    let priest_text = [
        "Priest: Thank you. You saved me.",
        "Priest: You look strange. You are not locals right?",
        "Robin: I am an adventurer.",
        "Robin: my ship was wrecked and I ended up here.",
        "Robin: Do you know any way out?",
        "Priest: No. I never leave this place.",
        "Robin: OK, I'll keep going east.",
        "Priest: East? The Grand Cliff? You'll never pass there",
        "Priest: But there is secret tunnel. ",
        "Priest: Go east and find a place full of sand.",
        "Priest: Throw the magic stone to the place",
        "Priest: God bless you, Amen."
    ]
    var priest_index:Int = 0
    var priest_count:Int = 0
    func priest_quest(){
        let priest_top = childNode(withName: "priest_top") as? SKSpriteNode
        priest_top?.removeFromParent();
        
        let priest = childNode(withName: "priest") as? SKSpriteNode
        let stand_up = SKAction.rotate(byAngle: CGFloat(-M_PI/2), duration: 1)
        let move  = SKAction.moveTo(y: (priest?.position.y)!+7.8, duration: 0)
        priest?.run(SKAction.sequence([stand_up,move]))
        if(face_left){
            priest?.texture = SKTexture(imageNamed: "priest_left")
        }
        else {
            priest?.texture = SKTexture(imageNamed: "priest_right")
        }
        priest_index = 1
        priest_count = priest_text.count-1
        priest?.physicsBody?.contactTestBitMask = 0
        priest?.physicsBody?.collisionBitMask = 0
        priest?.physicsBody?.categoryBitMask = 0
        priest?.physicsBody?.pinned = true
        priest?.physicsBody?.isDynamic = false
        callText(text: priest_text[0])
        
    }
    
    func secret_way(){
        for node in self.children{
            if(node.name == "chapter3_part1_secret"){
                if let secret:SKTileMapNode = node as? SKTileMapNode{
                    let dmg = SKAction.move(to: CGPoint(x: 1307.256, y: -1760), duration: 2)
                    let done = SKAction.run {
                        secret.removeFromParent()
                    }
                    secret.run(SKAction.sequence([dmg,done]))
                    shipGone = true
                    
                }
                break
            }
        }
    }
    
    var enter_way:Bool = false
    var doctor_index:Int = 0
    var doctor_count:Int = 0
    var meet_doctor = false
    let doctor_text = [
        "Doctor Who: Hey man, have you seen Panghu before?",
        "Robin: umm.... Who....?",
        "Doctor Who: How did you know my name?",
        "Robin: Why is your name Who?",
        "Doctor Who: I'll examplain later.",
        "Doctor Who: Anyway, Panghu is the priest in our team.",
        "Doctor Who: We got into a sandstorm and lost him yesterday.",
        "Robin: He was in the desert, and I got him out.",
        "Doctor Who: Oh! He is alive!",
        "Doctor Who: Can you tell my twin brother that",
        "Doctor Who: I am fine and I will be back next month",
        "Doctor Who: He lives in the snow field.",
        "Robin: Sure"
        
    ]
    func mission_doctor(){
        enter_way = false
        meet_doctor = true
        doctor_index = 1
        doctor_count = doctor_text.count-1
        let doctor = childNode(withName: "doctor") as? SKSpriteNode
        doctor?.physicsBody?.contactTestBitMask = 0
        doctor?.physicsBody?.collisionBitMask = 0
        doctor?.physicsBody?.categoryBitMask = 0
        doctor?.physicsBody?.pinned = true
        doctor?.physicsBody?.isDynamic = false
        callText(text: doctor_text[0])
    }
    
    var brother_index:Int = 0
    var brother_count:Int = 0
    var meet_brother = false
    let brother_text = [
       "Robin: Your rude brother says he will be back next week",
       "Qu: Make sense, make sense",
       "Robin: All right?",
       "Qu: Make sense, make snese"
    ]
    func mission_brother(){
        if(meet_doctor){
           meet_brother = true
           brother_index = 1
            brother_count = brother_text.count-1
           let doctor_2 = childNode(withName: "doctor_2") as? SKSpriteNode
           doctor_2?.physicsBody?.contactTestBitMask = 0
           doctor_2?.physicsBody?.collisionBitMask = 0
           doctor_2?.physicsBody?.categoryBitMask = 0
           doctor_2?.physicsBody?.pinned = true
           doctor_2?.physicsBody?.isDynamic = false
           callText(text: brother_text[0])
        }
    }
    
    
    func callText(text: String){
        self.prev_velocity = Int(self.player_speed)
        if(self.dev==false){
            self.player_speed=0
        }
        self.pause=true
        self.textbox?.isHidden=false
        
        if let t = self.textlabel{
            t.isHidden=false
            t.text=text
            t.fontSize = 20
        }
    }

    //function that hides text when users click the screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.textlabel?.isHidden=true
        self.textbox?.isHidden=true
        self.pause=false
        self.player_speed=CGFloat(prev_velocity)
        
        if(!introFinished){
            introIndex = introIndex + 1
            if(introIndex>=3){
                introFinished=true
            }
            callText(text: introText[introIndex])
            return
        }
        if(startedLao==true&&finishedLao==false&&conversationLao==false){
            laoIndex = laoIndex + 1
            if(laoIndex>=7){
                conversationLao=true
            }
            callText(text: laoText[laoIndex])
            return
        }
        if(startedSun==true&&finishedSun==false&&conversationSun==false){
            SunIndex = SunIndex + 1
            if(SunIndex>=5){
                conversationSun=true
            }
            callText(text: SunText[SunIndex])
            return
        }
        if(startedUncle==true&&finishedUncle==false&&conversationUncle==false){
            print("uncle touches")
            uncleIndex = uncleIndex + 1
            if(uncleIndex>=uncleText.count-1){
                conversationUncle=true
            }
            callText(text: uncleText[uncleIndex])
            return
        }
        if(mission_priest&&(priest_index<=priest_count)){
            callText(text: priest_text[priest_index])
            if(priest_index == priest_count){
                let texture = SKTexture(imageNamed: "magicstone")
                if((touchControlNode?.setinventory(tex: texture,category:3,name:"magicstone"))!){}
                else{
                    let magicstone = SKSpriteNode(imageNamed: "magicstone")
                    magicstone.physicsBody?.isDynamic = false
                    magicstone.physicsBody?.pinned = false
                    magicstone.physicsBody?.allowsRotation = false
                    magicstone.physicsBody?.affectedByGravity = true
                    magicstone.physicsBody?.categoryBitMask = 3
                    magicstone.physicsBody?.collisionBitMask = 3
                    magicstone.physicsBody?.categoryBitMask = 0
                    magicstone.name = "magicstone"
                    magicstone.position.x = (self.player?.position.x)!+10
                    magicstone.position.y = (self.player?.position.y)!
                }
            }
            priest_index = priest_index+1
        }
        if(meet_doctor&&(doctor_index<=doctor_count)){
            callText(text: doctor_text[doctor_index])
            doctor_index = doctor_index+1
        }
        if(meet_brother&&(brother_index<=brother_count)){
            callText(text: brother_text[brother_index])
            brother_index = brother_index+1
        }
    }
    
    // function to set up on screen control ui
    func setupControls(camera : SKCameraNode, scene: SKScene) {
        
        touchControlNode = TouchInputNode(frame: scene.frame)
        touchControlNode?.inputDelegate = self
        touchControlNode?.position = CGPoint.zero
        
        
        camera.addChild(touchControlNode!)
    }
    
    // MARK: Update Function
    // update function that handles player movements
    override func update(_ currentTime: TimeInterval) {
        if(Int((self.player?.position.y)!) < -1040 && !enter_way){
            enter_way = true
        }
        if(self.startedLao){
            if(Int((self.player?.position.x)!)>235){
                
                lao?.texture=SKTexture(imageNamed: "lao_right")
            }else{
                lao?.texture=SKTexture(imageNamed: "lao_left")
            }
        }
        if(self.left){
            // let player's ship gone
            if(!shipGone){
                        for node in self.children{
                            if(node.name == "ship"){
                                if let ship:SKTileMapNode = node as? SKTileMapNode{
                                    let dmg = SKAction.move(to: CGPoint(x: -5475.88, y: -1500), duration: 10)
                                    callText(text: "No! My ship!")
                                    let done = SKAction.run {
                                        ship.removeFromParent()
                                    }
                                    ship.run(SKAction.sequence([dmg,done]))
                                    shipGone = true
                                    
                                }
                                break
                            }
                        }
            }
            if let player = self.player{
//                player.position.x = (self.player?.position.x)!-2
                player.physicsBody?.velocity.dx = -(player_speed)
                if(self.nextStep==0 && !self.jump){
                    player.texture = SKTexture(imageNamed: "robin_back_right")
                    self.stepCount += 1
                    if(self.stepCount>=20){
                        self.stepCount=0
                        self.nextStep=1
                    }
                }else if (!self.jump){
                    player.texture = SKTexture(imageNamed: "robin_back_left")
                    self.stepCount += 1
                    if(self.stepCount>=20){
                        self.stepCount=0
                        self.nextStep=0
                    }
                }
            }
        }
        else if(self.right){
            if(!shipGone){
                        for node in self.children{
                            if(node.name == "ship"){
                                if let ship:SKTileMapNode = node as? SKTileMapNode{
                                    let dmg = SKAction.move(to: CGPoint(x: -5475.88, y: -1500), duration: 10)
                                    callText(text: "No! My ship!")
                                    let done = SKAction.run {
                                        ship.removeFromParent()
                                    }
                                    ship.run(SKAction.sequence([dmg,done]))
                                    shipGone = true
                                    
                                }
                                break
                            }
                        }
            }
            if let player = self.player{
//                player.position.x = (self.player?.position.x)!+2
                player.physicsBody?.velocity.dx = player_speed
                if(self.nextStep==0 && !self.jump){
                    player.texture = SKTexture(imageNamed: "robin_right")
                    self.stepCount += 1
                    if(self.stepCount>=20){
                        self.stepCount=0
                        self.nextStep=1
                    }
                }else if(!self.jump){
                    player.texture = SKTexture(imageNamed: "robin_left")
                    self.stepCount += 1
                    if(self.stepCount>=20){
                        self.stepCount=0
                        self.nextStep=0
                    }
                }
            }
        }
    }
    
    // MARK: Contact Handler
    // function to handle cotacts among player and map
    func didBegin(_ contact: SKPhysicsContact){
        if contact.bodyA.categoryBitMask == 1 && contact.bodyB.categoryBitMask == 3 {
            contact.bodyA.velocity.dx=0
            contact.bodyA.velocity.dy=0
        }
        if contact.bodyA.categoryBitMask == 3 && contact.bodyB.categoryBitMask == 1 {
            contact.bodyB.velocity.dx=0
            contact.bodyB.velocity.dy=0
        }
        if contact.bodyA.categoryBitMask == 1 && contact.bodyB.node?.name == "map" {
            contact.bodyA.velocity.dx=0
            contact.bodyA.velocity.dy=physicsWorld.gravity.dy
        }
        if contact.bodyA.node?.name == "map" && contact.bodyB.categoryBitMask == 1 {
            contact.bodyB.velocity.dx=0
            contact.bodyA.velocity.dy=physicsWorld.gravity.dy
        }
        if contact.bodyA.categoryBitMask == 1 && contact.bodyB.categoryBitMask == 6 {
            contact.bodyA.velocity.dx=0
            missionLao()
        }

        if contact.bodyA.categoryBitMask == 6 && contact.bodyB.categoryBitMask == 1 {
            contact.bodyB.velocity.dx=0
            missionLao()
        }
        if contact.bodyA.categoryBitMask == 1 && contact.bodyB.categoryBitMask == 24 {
            contact.bodyA.velocity.dx=0
            missionSun()
        }

        if contact.bodyA.categoryBitMask == 24 && contact.bodyB.categoryBitMask == 1 {
            contact.bodyB.velocity.dx=0
            missionSun()
        }
        if contact.bodyA.categoryBitMask == 11 && contact.bodyB.categoryBitMask == 1 {
            contact.bodyB.velocity.dx=0
            mission_doctor()
        }
        if contact.bodyA.categoryBitMask == 1 && contact.bodyB.categoryBitMask == 11 {
            contact.bodyA.velocity.dx=0
            mission_doctor()
        }
        if contact.bodyA.categoryBitMask == 12 && contact.bodyB.categoryBitMask == 1 {
            contact.bodyB.velocity.dx=0
            mission_brother()
        }
        if contact.bodyA.categoryBitMask == 1 && contact.bodyB.categoryBitMask == 12 {
            contact.bodyA.velocity.dx=0
            mission_brother()
        }
        if contact.bodyA.categoryBitMask == 3 && contact.bodyB.categoryBitMask == 6 {
            if(contact.bodyA.node?.name=="snowman"){
                print("finish Lao")
                contact.bodyA.node?.removeFromParent()
                self.finishedLao=true
                callText(text: "Lao: OHHHHHHHHH my Snowman")
                self.stop1?.removeFromParent()
                self.stop2?.removeFromParent()
                self.stop3?.removeFromParent()
                self.stop4?.removeFromParent()
            }
        }
        if contact.bodyA.categoryBitMask == 6 && contact.bodyB.categoryBitMask == 3 {
            if(contact.bodyB.node?.name=="snowman"){
                print("finish Lao")
                contact.bodyB.node?.removeFromParent()
                self.finishedLao=true
                callText(text: "Lao: OHHHHHHHHH my Snowman")
                self.stop1?.removeFromParent()
                self.stop2?.removeFromParent()
                self.stop3?.removeFromParent()
                self.stop4?.removeFromParent()
            }
        }
        if contact.bodyA.categoryBitMask == 3 && contact.bodyB.categoryBitMask == 24 {
            if(contact.bodyA.node?.name=="grass"){
                print("finish sun")
                contact.bodyA.node?.removeFromParent()
                self.finishedSun=true
                callText(text: "SUN: gracias")
            }
        }
        if contact.bodyB.categoryBitMask == 3 && contact.bodyA.categoryBitMask == 24 {
            if(contact.bodyB.node?.name=="grass"){
                print("finish sun")
                contact.bodyB.node?.removeFromParent()
                self.finishedSun=true
                callText(text: "SUN: gracias")
            }
        }
        if contact.bodyA.categoryBitMask == 1 && contact.bodyB.categoryBitMask == 7 {
            let movetoch3 = SKAction.moveBy(x: -1900, y: -808, duration: 0)
            self.player?.run(movetoch3);
        }
        if contact.bodyA.categoryBitMask == 7 && contact.bodyB.categoryBitMask == 1 {
            let movetoch3 = SKAction.moveBy(x: -1900, y: -808, duration: 0)
            self.player?.run(movetoch3);
        }
        
        if contact.bodyA.categoryBitMask == 9 && contact.bodyB.categoryBitMask == 1 {
            if(!self.mission_priest){
                callText(text: "Priest: water....I need water....")
                
            }
            
        }
        if contact.bodyA.categoryBitMask == 1 && contact.bodyB.categoryBitMask == 9 {
            if(!self.mission_priest){
                callText(text: "Priest: water....I need water....")
            }
        }
        if contact.bodyA.categoryBitMask == 9 && contact.bodyB.node?.name == "water" {
            priest_quest()
            self.mission_priest = true
            contact.bodyB.node?.removeFromParent()
        }
        if contact.bodyA.node?.name == "water" && contact.bodyB.categoryBitMask == 9 {
            priest_quest()
            self.mission_priest = true
            contact.bodyA.node?.removeFromParent()
        }
        if contact.bodyA.categoryBitMask == 1 && contact.bodyB.node?.name == "悬崖" {
                callText(text: "Robin: I need find another path...")
        }
        if contact.bodyB.categoryBitMask == 1 && contact.bodyA.node?.name == "悬崖" {
                callText(text: "Robin: I need find another path...")
        }
        if contact.bodyB.node?.name == "magicstone" && contact.bodyA.node?.name == "暗道" {
            contact.bodyB.node?.removeFromParent()
            contact.bodyA.node?.removeFromParent()
            secret_way()
        }
        if contact.bodyB.node?.name == "暗道" && contact.bodyA.node?.name == "magicstone" {
            contact.bodyB.node?.removeFromParent()
            contact.bodyA.node?.removeFromParent()
            secret_way()
        }
        // Uncle and Ninja part
        if contact.bodyA.categoryBitMask == 1 && contact.bodyB.categoryBitMask == 20 {
            contact.bodyA.velocity.dx=0
            missionUncle()
        }
        
        if contact.bodyA.categoryBitMask == 20 && contact.bodyB.categoryBitMask == 1 {
            contact.bodyB.velocity.dx=0
            missionUncle()
        }
        
        if contact.bodyA.node?.name == "Ninja" && contact.bodyB.categoryBitMask == 22 {
            callText(text: "Ninja: Thank you, Robin!")
            self.ninjaEatFood()
            self.finishedUncle=true
            
            self.stop9?.removeFromParent()
            self.stop10?.removeFromParent()
            self.stop11?.removeFromParent()
            self.stop12?.removeFromParent()
            
            contact.bodyA.node?.physicsBody?.contactTestBitMask = 0
            contact.bodyA.node?.physicsBody?.collisionBitMask = 0
            contact.bodyA.node?.physicsBody?.categoryBitMask = 0
            contact.bodyA.node?.physicsBody?.pinned = true
            contact.bodyA.node?.physicsBody?.isDynamic = false
        }
        if contact.bodyA.categoryBitMask == 22 && contact.bodyB.node?.name == "Ninja" {
            callText(text: "Ninja: Thank you, Robin!")
            self.ninjaEatFood()
            self.finishedUncle=true
            
            self.stop9?.removeFromParent()
            self.stop10?.removeFromParent()
            self.stop11?.removeFromParent()
            self.stop12?.removeFromParent()
            
            contact.bodyB.node?.physicsBody?.contactTestBitMask = 0
            contact.bodyB.node?.physicsBody?.collisionBitMask = 0
            contact.bodyB.node?.physicsBody?.categoryBitMask = 0
            contact.bodyB.node?.physicsBody?.pinned = true
            contact.bodyB.node?.physicsBody?.isDynamic = false
        }
    }
    
    /**
     Summer part - Zhenxuan Ouyang
     */
    var uncleIndex = 0
    var startedUncle = false
    var finishedUncle = false
    var conversationUncle = false
    let uncleText = [
        "Uncle: Yo, my man?",
        "Robin: Oh hello? Do you know...",
        "Uncle: What's your name?",
        "Robin: Robin",
        "Uncle: Robin? Good to see you.",
        "Robin: Can you tell me the way to leave here?",
        "Uncle: Yes, but can you help me to save my brother? ",
        "Uncle: He is sick and may need some mushrooms and water",
        "Uncle: before getting",
        "Uncle: You can take him to the destination,",
        "Uncle: and he will guide you out",
        "Robin: Err, alright..."
    ]
    func missionUncle(){
        if(finishedUncle){
            
            callText(text: "Uncle: Thank you, Robin...")
        }else{
            if(!startedUncle){
                startedUncle = true
                callText(text: uncleText[0])
            }
            else{
                callText(text: "Uncle: Go and help my brother....")
            }
        }
    }
    
    var ninjaHealed = false
    func isNinjaHealed() -> Bool{
        var water = false
        var mushroom = false
        let item_amount = self.touchControlNode?.itemName.count
        for i in stride(from: 0, to: item_amount!, by: 1){
            if self.touchControlNode?.itemName[i] == "water" {
                water = true
            }
            if self.touchControlNode?.itemName[i] == "mushroom" {
                mushroom = true
            }
        }
        return water&&mushroom

    }
    
    func ninjaEatFood(){
        let item_amount = self.touchControlNode?.itemName.count
        var haveWater = true
        var haveMushroom = true
        for i in stride(from: 0, to: item_amount!, by: 1){
            if(self.touchControlNode?.itemName[i] == "water" && haveWater){
                self.touchControlNode?.selected = i
                self.touchControlNode?.useItem()
                haveWater = false
                self.touchControlNode?.selected = -1
            }
            if(self.touchControlNode?.itemName[i] == "mushroom" && haveMushroom){
                self.touchControlNode?.selected = i
                self.touchControlNode?.useItem()
                haveMushroom = false
                self.touchControlNode?.selected = -1
            }
        }
    }
}
