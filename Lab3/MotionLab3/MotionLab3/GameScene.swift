//
//  GameScene.swift
//  HKBTCN
//
//  Created by 梅沈潇 on 10/9/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

protocol GameViewControllerDelegate: class {
    func finishGame(inputProperty:String)
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var label : SKLabelNode?
    private var scoreBoard: SKLabelNode?
    private var spinnyNode : SKShapeNode?
    private var marioNode: SKSpriteNode?
    private var jetNode: SKSpriteNode?
    private var bossNode: SKSpriteNode?
    private var bulletNode: SKSpriteNode?
    private var finishButton: SKSpriteNode?
    private var isLost: Bool?
    
    var gameViewControllerDelegate:GameViewControllerDelegate?
//    var gameController: GameViewController?

    var score = 0
    let motion = CMMotionManager()
    func startMotionUpdates(){
        // some internal inconsistency here: we need to ask the device manager for device
        
        if self.motion.isDeviceMotionAvailable{
            self.motion.deviceMotionUpdateInterval = 0.1
            self.motion.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: self.handleMotion )
        }
    }
    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
        if let gravity = motionData?.gravity {
            if let jetNode = self.jetNode {
            self.physicsWorld.gravity = CGVector(dx: CGFloat(9.8*gravity.x*2), dy: CGFloat(0))
            if(gravity.x>0){
                if((jetNode.physicsBody?.velocity.dx)!<CGFloat(0)){
                    jetNode.physicsBody?.velocity.dx=0
                }
            }
            if(gravity.x<0){
                if((jetNode.physicsBody?.velocity.dx)!>CGFloat(0)){
                    jetNode.physicsBody?.velocity.dx=0
                }
            }
            }
        }
    }
    override func didMove(to view: SKView) {
        
        if let gameLifeCount = self.userData?.value(forKey: "gameLifeCount") {
            print("gameLifeCount is :\(gameLifeCount)")
        }
        
        self.isLost=false
        physicsWorld.contactDelegate = self
        let background = SKSpriteNode(imageNamed: "sky.jpg")
        background.zPosition=0
//        background.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(background)
        physicsWorld.gravity = .zero
        self.startMotionUpdates()
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        self.scoreBoard = self.childNode(withName: "//scoreLabel") as? SKLabelNode
        self.bossNode = self.childNode(withName: "boss") as? SKSpriteNode
        self.bulletNode = self.childNode(withName: "bullet") as? SKSpriteNode
        self.bulletNode?.zPosition=1
        self.bulletNode?.isHidden=true
        self.bulletNode?.physicsBody?.isDynamic=false
//        self.bossNode = self.childNode(withName: "bullet") as? SKSpriteNode
        self.bossNode?.zPosition=1
        self.bossNode?.isHidden=true
        self.bossNode?.physicsBody?.isDynamic=false
//        self.finishButton?.isHidden=true
        addJet()
        
        // add the return button
        addFinishButton()
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addEnemy),
                SKAction.wait(forDuration: 2.0)
                ])
        ))
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addBullet),
                SKAction.wait(forDuration: 0.5)
                ])
        ))
        
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
            label.zPosition=1
            label.fontSize=40
        }
        
        if let label = self.scoreBoard {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
            label.zPosition=1
            label.fontSize=40
            label.text="Your Score is: \(score)"
        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
        
    }
    
    func addFinishButton(){
        self.finishButton = self.childNode(withName: "finishBtn") as? SKSpriteNode
        self.finishButton?.isHidden = false
        NSLog("add finish button")
        self.finishButton?.zPosition=1
    }
    
    func addJet(){
        self.jetNode = self.childNode(withName: "jet") as? SKSpriteNode
        self.jetNode?.zPosition=1
    }
    
    func addBullet(){
        if (!self.isLost!){
            if let n = self.bulletNode?.copy() as! SKSpriteNode? {
                n.isHidden=false
                n.physicsBody?.isDynamic=true
                n.position.x=(self.jetNode?.position.x)!
                let actualDuration = CGFloat(1.0)

                // Create the actions
                let actionMove = SKAction.move(to: CGPoint(x: n.position.x, y: size.height),duration: TimeInterval(actualDuration))
                
                let actionMoveDone = SKAction.removeFromParent()
                n.run(SKAction.sequence([actionMove, actionMoveDone]))
                self.addChild(n)
            }
        }
    }
    
    func addEnemy(){
        if (!self.isLost!){
            if let n = self.bossNode?.copy() as! SKSpriteNode? {
                n.position.x=random(min: CGFloat((self.bossNode?.size.width)!/2-size.width/2), max: CGFloat(size.width/2-(self.bossNode?.size.width)!/2))
                n.isHidden=false
                n.physicsBody?.isDynamic=true
                let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
                
                // Create the actions
                let actionMove = SKAction.move(to: CGPoint(x: n.position.x, y: n.position.y-size.height),
                                               duration: TimeInterval(actualDuration))
                let actionMoveDone = SKAction.removeFromParent()
                n.run(SKAction.sequence([actionMove, actionMoveDone]))
                self.addChild(n)
            }
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        if(self.isLost!){
            addChild((self.jetNode)!)
//            self.finishButton?.removeFromParent()
            self.jetNode?.isHidden=false
            self.label?.text="STAR WAR"
            self.jetNode?.physicsBody?.isDynamic=true
            self.isLost=false
            self.score=0
            self.scoreBoard?.text="Your Score is: \(self.score)"
//            self.scoreBoard?.isHidden=false
//            addChild(self.finishButton!)
        }
        for t in touches {
            self.touchDown(atPoint: t.location(in: self))
            
            let location = t.location(in: self)
            
            if(self.atPoint(location).name == "finishBtn"){
                gameViewControllerDelegate?.finishGame(inputProperty: "call game view controller method")
            }
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    func crash(jet: SKSpriteNode, enemy: SKSpriteNode) {
        if(enemy.physicsBody!.isDynamic){
            print("Crash")
            jet.removeFromParent()
            jet.isHidden=true
            let x = jet.position.x
            let y = jet.position.y
            let boom = SKSpriteNode(imageNamed: "boom")
            boom.size = CGSize(width:jet.size.width,height:jet.size.height)
            boom.position = CGPoint(x: x, y: y)
            self.addChild(boom)
            boom.run(SKAction.fadeOut(withDuration: 2))
            boom.zPosition=1
            
            self.jetNode?.physicsBody?.isDynamic=false
            
            enemy.removeFromParent()
            self.label?.text="Touch to restart"
            self.isLost=true
//            self.scoreBoard?.isHidden=true
            //        SKAction.stop()
//            addFinishButton()
        }
    }
    
    func hit(bullet: SKSpriteNode, enemy: SKSpriteNode) {
        if(enemy.physicsBody!.isDynamic&&bullet.physicsBody!.isDynamic){
            print("hit")
            bullet.removeFromParent()
            let x = bullet.position.x
            let y = bullet.position.y
            let boom = SKSpriteNode(imageNamed: "boom")
            boom.size = CGSize(width:bullet.size.width,height:bullet.size.height)
            boom.position = CGPoint(x: x, y: y)
            self.addChild(boom)
            boom.run(SKAction.fadeOut(withDuration: 2))
            boom.zPosition=1
            enemy.removeFromParent()
            self.score+=1
            self.scoreBoard?.text="Your Score is: \(self.score)"
            //        SKAction.stop()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
//        print("contact")
        if contact.bodyA.node?.name == "jet"{
            if contact.bodyB.node?.name == "boss"
            {
                crash(jet: contact.bodyA.node as! SKSpriteNode, enemy: contact.bodyB.node as! SKSpriteNode)
            }
        }
        if contact.bodyA.node?.name == "bullet"{
            if contact.bodyB.node?.name == "boss"
            {
                hit(bullet: contact.bodyA.node as! SKSpriteNode, enemy: contact.bodyB.node as! SKSpriteNode)
            }
        }
        if contact.bodyB.node?.name == "bullet"{
            if contact.bodyA.node?.name == "boss"
            {
                hit(bullet: contact.bodyB.node as! SKSpriteNode, enemy: contact.bodyA.node as! SKSpriteNode)
            }
        }
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    override func willMove(from view: SKView) {
        print("in the willMove function")
    }
}
