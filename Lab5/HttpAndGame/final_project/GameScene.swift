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
    
    var gameViewControllerDelegate:GameViewControllerDelegate?
    
    var left:Bool = false
    var right:Bool = false
    var jump: Bool = false
    var orientation: Int = 1
    var nextStep:Int = 0
    var stepCount:Int = 0
    var inventory1: SKSpriteNode?
    var textbox: SKSpriteNode?
    var textlabel: SKLabelNode?
    var shipGone:Bool = false
    var player_speed: CGFloat = 100
    
    // initial sprite nodes
    var player: SKSpriteNode?
    var label : SKLabelNode?
    var touchControlNode : TouchInputNode?
    
    // MARK: Machine Learning part
    let theAction = ActionPredict.sharedInstance
    
    // MARK: Button Control Functions
    func follow(command: String?) {
        switch (command!){
        case ("left"):
            self.textlabel?.isHidden=true
            self.textbox?.isHidden=true
            self.left = true
            self.right = false
            self.orientation = -1
        case ("right"):
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
            gameViewControllerDelegate?.finishGame(inputProperty: "call game view controller method")
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
                if((touchControlNode?.setinventory(tex: nearnode!.texture!,category:(nearnode?.physicsBody?.categoryBitMask)!))!){
                    callText(text: "You Pick Up the ",object:(nearnode?.name!)!)
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
                //                item?.physicsBody?.pinned=true
                item.position.x = (self.player?.position.x)! + CGFloat(self.orientation*6)
                item.position.y = (self.player?.position.y)! + 24
                item.physicsBody?.velocity.dx = CGFloat(self.orientation * 200)
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
            if((touchControlNode?.setinventory(tex: nearnode!.texture!,category:nearnode!.physicsBody!.categoryBitMask))!){
                callText(text: "You Pick Up the ",object:(nearnode?.name!)!)
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
        self.player?.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 18, height: 35))
        self.player?.physicsBody?.allowsRotation = false
        self.player?.physicsBody?.categoryBitMask = 1
        self.player?.physicsBody?.collisionBitMask = 1
        self.player?.physicsBody?.contactTestBitMask = 1
        self.player?.physicsBody?.affectedByGravity = true
        self.player?.physicsBody?.mass = 1
        self.player?.physicsBody?.friction = 0.6
        
        // set up text which will pop up when pick up an item
        self.textbox = camera?.childNode(withName: "Textbox") as? SKSpriteNode
        self.textlabel = camera?.childNode(withName: "Textlabel") as? SKLabelNode
        self.textbox?.isHidden=true
        self.textlabel?.isHidden=true
        self.textbox?.zPosition=13
        self.textlabel?.zPosition=14
        
    }
    
    // once pick up an item, show tedt on the screen
    func setupText(camera : SKCameraNode, scene: SKScene,text:String) {
        
        touchControlNode = TouchInputNode(frame: scene.frame)
        touchControlNode?.inputDelegate = self
        touchControlNode?.position = CGPoint.zero
        
        
        camera.addChild(touchControlNode!)
    }
    
    func callText(text: String, object:String){
        self.textbox?.isHidden=false
        
        if let t = self.textlabel{
            t.isHidden=false
            t.text=text+object
        }
    }
    
    //function that hides text when users click the screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.textlabel?.isHidden=true
        self.textbox?.isHidden=true
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
//            contact.bodyA.velocity.dy=0
        }
        if contact.bodyA.node?.name == "map" && contact.bodyB.categoryBitMask == 1 {
            contact.bodyB.velocity.dx=0
//            contact.bodyB.velocity.dy=0
        }
        
    }
    
    
}
