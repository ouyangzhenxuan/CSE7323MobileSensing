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

protocol GameViewControllerDelegate: class {
    func finishGame(inputProperty:String)
}

// gamescene that manages entire game
class GameScene: SKScene,ControlInputDelegate,SKPhysicsContactDelegate{
    // initial variables
    
    var dev = false
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
    var textlabel: SKLabelNode?
    var shipGone:Bool = false
    var player_speed: CGFloat = 100
    
    // initial sprite nodes
    var player: SKSpriteNode?
    var lao: SKSpriteNode?
    
    var uncle: SKSpriteNode?
    var ninja: SKSpriteNode?
    var ninja_destination: SKSpriteNode?
    
    var label : SKLabelNode?
    var touchControlNode : TouchInputNode?
    
    
    // MARK: Machine Learning part
    let theAction = ActionPredict.sharedInstance
    
    // MARK: Button Control Functions
    func follow(command: String?) {
        if(self.pause&&self.dev==false){
            return
        }
        switch (command!){
        case ("left"):
            scene?.view?.isPaused = false
            self.textlabel?.isHidden=true
            self.textbox?.isHidden=true
            self.left = true
            self.right = false
            self.orientation = -1
        case ("right"):
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
                if(self.theAction.getPredictedAction() == "droppingdown"){
                    self.eatItem()
                }else if(self.theAction.getPredictedAction() == "throwing"){
                    self.throwItem()
                }else if(self.theAction.getPredictedAction() == "pickingup"){
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
//            var nearest = 99999
//            var nearnode: SKSpriteNode? = nil
//            for node in self.children{
//                if(node.physicsBody?.categoryBitMask==2||node.physicsBody?.categoryBitMask==3){
//                    let dis = abs((self.player?.position.x)! - node.position.x)+abs((self.player?.position.y)! - node.position.y)
////                    print("nearnode dis:",Int(dis))s
//                    if Int(dis) < nearest{
//                        nearest = Int(dis)
//                        nearnode = node as? SKSpriteNode
//                    }
//                }
//            }
            
//            if(nearnode?.name != nil&&nearest<40){
//                if((touchControlNode?.setinventory(tex: nearnode!.texture!,category:(nearnode?.physicsBody?.categoryBitMask)!,name:nearnode!.name!))!){
//                    callText(text: "You Pick Up the "+((nearnode?.name!)!))
//                    nearnode?.removeFromParent()}
//            }
            self.actionPickup()
        default:
            print("Button: \(String(describing: command))")
        }
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
        
        if(self.touchControlNode?.checkItemCategory()==3||self.touchControlNode?.checkItemCategory()==21){
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
                if self.finishedUncle == true{
                    return
                }
                self.ninjaHealed = self.isNinjaHealed()
                if self.ninjaHealed == false{
                    callText(text: "I need some water and mushrooms...")
                    return
                }
                self.ninja?.texture = SKTexture.init(imageNamed: "ninja_left")
            }
            
            if((touchControlNode?.setinventory(tex: nearnode!.texture!, category:nearnode!.physicsBody!.categoryBitMask,name:nearnode!.name!))!){
                callText(text: "You Pick Up the "+((nearnode?.name!)!))
                nearnode?.removeFromParent()}
        }
    }
    
    // MARK: Didmove Function
    override func didMove(to view: SKView) {
        //set up game world with initial pyhsics and camera
        physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        setupControls(camera: camera!, scene: self)
        
        // set up main player
        self.player = childNode(withName: "Robin") as? SKSpriteNode
        self.player?.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 18, height: 30))
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
        
//        self.lao?.physicsBody?.categoryBitMask = 5
//        self.lao?.physicsBody?.collisionBitMask = 5
//        
//        print(self.lao?.physicsBody?.categoryBitMask)
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
    
    var get_water = false;
    
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
        
        if(startedUncle==true&&finishedUncle==false&&conversationUncle==false){
            print("uncle touches")
            uncleIndex = uncleIndex + 1
            if(uncleIndex>=uncleText.count-1){
                conversationUncle=true
            }
            callText(text: uncleText[uncleIndex])
            return
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
                                    let dmg = SKAction.move(to: CGPoint(x: -674.826, y: -100), duration: 10)
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
                                    let dmg = SKAction.move(to: CGPoint(x: -674.826, y: -100), duration: 10)
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
        print(contact.bodyA.node?.name, contact.bodyB.node?.name)
        print(contact.bodyA.categoryBitMask, contact.bodyB.categoryBitMask)
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
        if contact.bodyA.categoryBitMask == 3 && contact.bodyB.categoryBitMask == 6 {
            print(contact.bodyA.node?.name)
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
            print(contact.bodyB.node?.name)
            if(contact.bodyB.node?.name=="snowman"){
                print("finish Lao")
                contact.bodyB.node?.removeFromParent()
                self.finishedLao=true
                
                self.stop1?.removeFromParent()
                self.stop2?.removeFromParent()
                self.stop3?.removeFromParent()
                self.stop4?.removeFromParent()
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
            if(!self.get_water){
                callText(text: "Knight:water....I need water....")
                
            }
            
        }
        if contact.bodyA.categoryBitMask == 1 && contact.bodyB.categoryBitMask == 9 {
            if(!self.get_water){
                callText(text: "Knight:water....I need water....")
            }
        }
        if contact.bodyA.categoryBitMask == 1 && contact.bodyB.node?.name == "悬崖" {
                callText(text: "Robin: I need find another path...")
        }
        if contact.bodyB.categoryBitMask == 1 && contact.bodyA.node?.name == "悬崖" {
                callText(text: "Robin: I need find another path...")
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
            print(contact.bodyB.node?.name)
            print("hello")
            //            if(contact.bodyA.node?.name=="Ninja"){
            print("finish uncle&ninja")
            callText(text: "Ninja: Thank you, Robin!")
            //                contact.bodyA.node?.removeFromParent()
            self.finishedUncle=true
            
            self.stop5?.removeFromParent()
            self.stop6?.removeFromParent()
            self.stop7?.removeFromParent()
            self.stop8?.removeFromParent()
            
            contact.bodyA.node?.physicsBody?.contactTestBitMask = 0
            contact.bodyA.node?.physicsBody?.collisionBitMask = 0
            contact.bodyA.node?.physicsBody?.categoryBitMask = 0
            contact.bodyA.node?.physicsBody?.pinned = true
            contact.bodyA.node?.physicsBody?.isDynamic = false
//            self.ninjaHealed = false
//            }
        }
        if contact.bodyA.categoryBitMask == 22 && contact.bodyB.node?.name == "Ninja" {
            print(contact.bodyB.node?.name)
            print("hello")
            //            if(contact.bodyA.node?.name=="Ninja"){
            print("finish uncle&ninja")
            callText(text: "Ninja: Thank you, Robin!")
            //                contact.bodyB.node?.removeFromParent()
            self.finishedUncle=true
            
            self.stop5?.removeFromParent()
            self.stop6?.removeFromParent()
            self.stop7?.removeFromParent()
            self.stop8?.removeFromParent()
            
            contact.bodyB.node?.physicsBody?.contactTestBitMask = 0
            contact.bodyB.node?.physicsBody?.collisionBitMask = 0
            contact.bodyB.node?.physicsBody?.categoryBitMask = 0
            contact.bodyB.node?.physicsBody?.pinned = true
            contact.bodyB.node?.physicsBody?.isDynamic = false
//            self.ninjaHealed = false
//            }
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
        "Lao: What's your name?",
        "Robin: Robin",
        "Lao: Robin? Good to see you.",
        "Robin: Can you tell me the way to leave the desert?",
        "Lao: Yes, but can you help me to save my brother? ",
        "Lao: He is sick and may need some mushrooms and water",
        "Lao: before getting",
        "Lao: You can take him to the destination,",
        "Lao: and he will guide you out",
        "Robin: Err, alright..."
    ]
    func missionUncle(){
        if(finishedUncle){
            callText(text: "Uncle: Thank you, Bob...")
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
    
//    func pickupNinja(ninjaNode: SKSpriteNode){
//        if ninjaNode != nil{
//
//        }
//        if(ninjaNode.name == "Ninja"){
//            if isNinjaHealed() == false{
//                callText(text: "I need some water and mushrooms...")
//                return
//            }
//        }
//    }
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
//        for i in 0...item_amount{
//            return
//        }
    }
    
    
    
}
