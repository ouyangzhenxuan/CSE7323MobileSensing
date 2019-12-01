//
//  GameScene2.swift
//  final_project
//
//  Created by Zhenxuan Ouyang on 11/24/19.
//  Copyright © 2019 5324. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit
import CoreMotion
import CoreML
import UIKit

// delegate the predict_action() to other class
protocol ActionDelegate2 {
    func actionBegin()
    func actionDone()
    func updatePredictedAction()
    func getPredictedAction() -> String
}

protocol GameViewControllerDelegate2: class {
    func finishGame(inputProperty:String)
}


class GameScene2: SKScene,SKPhysicsContactDelegate,ControlInputDelegate{
    
//    var player: SKSpriteNode?
//    var touchControlNode : TouchInputNode?
//    var gameViewControllerDelegate2: GameViewControllerDelegate2?
    
    var dev = false
    var gameViewControllerDelegate2: GameViewControllerDelegate2?
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
    var textlabel: SKLabelNode?
    var shipGone:Bool = false
    var player_speed: CGFloat = 100
    
    // initial sprite nodes
    var player: SKSpriteNode?
    var lao: SKSpriteNode?
    var label : SKLabelNode?
    var touchControlNode : TouchInputNode?
    
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
    
    // MARK: Machine Learning part
    let theAction = ActionPredict.sharedInstance
    
    override func didMove(to view: SKView) {
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
    }
    
    func setupControls(camera : SKCameraNode, scene: SKScene) {
        
        touchControlNode = TouchInputNode(frame: scene.frame)
        touchControlNode?.inputDelegate = self
        touchControlNode?.position = CGPoint.zero
        
        
        camera.addChild(touchControlNode!)
    }
    
    func follow(command: String?) {
        if(self.pause&&self.dev==false){
            return
        }
        switch (command!){
        case ("left"):
            print("left")
            scene?.view?.isPaused = false
            self.textlabel?.isHidden=true
            self.textbox?.isHidden=true
            self.left = true
            self.right = false
            self.orientation = -1
        case ("right"):
            print("right")
            scene?.view?.isPaused = false
            self.textlabel?.isHidden=true
            self.textbox?.isHidden=true
            self.right = true
            self.left = false
            self.orientation = 1
        // jump function
        case ("A"):
            print("A")
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
            var nearest = 99999
            var nearnode: SKSpriteNode? = nil
            for node in self.children{
                if(node.physicsBody?.categoryBitMask==2||node.physicsBody?.categoryBitMask==3){
                    let dis = abs((self.player?.position.x)! - node.position.x)+abs((self.player?.position.y)! - node.position.y)
                    print("nearnode dis:",Int(dis))
                    if Int(dis) < nearest{
                        nearest = Int(dis)
                        nearnode = node as? SKSpriteNode
                    }
                }
            }
            if(nearnode?.name != nil&&nearest<40){
                if((touchControlNode?.setinventory(tex: nearnode!.texture!,category:(nearnode?.physicsBody?.categoryBitMask)!,name:nearnode!.name!))!){
                    callText(text: "You Pick Up the "+((nearnode?.name!)!))
                    nearnode?.removeFromParent()}
            }
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
        
        if(self.touchControlNode?.checkItemCategory()==3){
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
        for node in self.children{
            if(node.physicsBody?.categoryBitMask==2||node.physicsBody?.categoryBitMask==3){
                let dis = abs((self.player?.position.x)! - node.position.x)+abs((self.player?.position.y)! - node.position.y)
                if Int(dis) < nearest{
                    nearest = Int(dis)
                    nearnode = node as? SKSpriteNode
                }
            }
        }
        if(nearnode?.name != nil&&nearest<40){
            if((touchControlNode?.setinventory(tex: nearnode!.texture!,category:nearnode!.physicsBody!.categoryBitMask,name:nearnode!.name!))!){
                callText(text: "You Pick Up the "+((nearnode?.name!)!))
                nearnode?.removeFromParent()}
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
        }
    }
    
    //function that hides text when users click the screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.textlabel?.isHidden=true
        self.textbox?.isHidden=true
        self.pause=false
        self.player_speed=CGFloat(prev_velocity)
        
//        if(!introFinished){
//            introIndex = introIndex + 1
//            if(introIndex>=3){
//                introFinished=true
//            }
//            callText(text: introText[introIndex])
//            return
//        }
//        if(startedLao==true&&finishedLao==false&&conversationLao==false){
//            laoIndex = laoIndex + 1
//            if(laoIndex>=7){
//                conversationLao=true
//            }
//            callText(text: laoText[laoIndex])
//            return
//        }
    }
    
    override func update(_ currentTime: TimeInterval) {
//        if(self.startedLao){
//            if(Int((self.player?.position.x)!)>235){
//                
//                lao?.texture=SKTexture(imageNamed: "lao_right")
//            }else{
//                lao?.texture=SKTexture(imageNamed: "lao_left")
//            }
//        }
        if(self.left){
            // let player's ship gone
//            if(!shipGone){
//                for node in self.children{
//                    if(node.name == "ship"){
//                        if let ship:SKTileMapNode = node as? SKTileMapNode{
//                            let dmg = SKAction.move(to: CGPoint(x: -674.826, y: -100), duration: 10)
//                            let done = SKAction.run {
//                                ship.removeFromParent()
//                            }
//                            ship.run(SKAction.sequence([dmg,done]))
//                            shipGone = true
//
//                        }
//                        break
//                    }
//                }
//            }
//            print("Left")
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
//            if(!shipGone){
//                for node in self.children{
//                    if(node.name == "ship"){
//                        if let ship:SKTileMapNode = node as? SKTileMapNode{
//                            let dmg = SKAction.move(to: CGPoint(x: -674.826, y: -100), duration: 10)
//                            let done = SKAction.run {
//                                ship.removeFromParent()
//                            }
//                            ship.run(SKAction.sequence([dmg,done]))
//                            shipGone = true
//
//                        }
//                        break
//                    }
//                }
//            }
            
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
            print("maye")
            contact.bodyA.velocity.dy=physicsWorld.gravity.dy
        }
        if contact.bodyA.node?.name == "map" && contact.bodyB.categoryBitMask == 1 {
            contact.bodyB.velocity.dx=0
            print("maye")
            contact.bodyA.velocity.dy=physicsWorld.gravity.dy
        }
//        if contact.bodyA.categoryBitMask == 1 && contact.bodyB.categoryBitMask == 6 {
//            print("sm")
//            contact.bodyA.velocity.dx=0
//            missionLao()
//        }
//        if contact.bodyA.categoryBitMask == 6 && contact.bodyB.categoryBitMask == 1 {
//            print("sm")
//            contact.bodyB.velocity.dx=0
//            missionLao()
//        }
//        if contact.bodyA.categoryBitMask == 3 && contact.bodyB.categoryBitMask == 6 {
//            print(contact.bodyA.node?.name)
//            if(contact.bodyA.node?.name=="snowman"){
//                print("finish Lao")
//                contact.bodyA.node?.removeFromParent()
//                self.finishedLao=true
//                callText(text: "Lao: OHHHHHHHHH my Snowman")
//                self.stop1?.removeFromParent()
//                self.stop2?.removeFromParent()
//                self.stop3?.removeFromParent()
//                self.stop4?.removeFromParent()
//            }
//        }
//        if contact.bodyA.categoryBitMask == 6 && contact.bodyB.categoryBitMask == 3 {
//            print(contact.bodyB.node?.name)
//            if(contact.bodyB.node?.name=="snowman"){
//                print("finish Lao")
//                contact.bodyB.node?.removeFromParent()
//                self.finishedLao=true
//                callText(text: "Lao: OHHHHHHHHH my Snowman")
//                self.stop1?.removeFromParent()
//                self.stop2?.removeFromParent()
//                self.stop3?.removeFromParent()
//                self.stop4?.removeFromParent()
//            }
//        }
        
    }
    
}
