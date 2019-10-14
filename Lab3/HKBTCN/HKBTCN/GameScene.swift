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
    private var hp: SKLabelNode?
    private var scoreBoard: SKLabelNode?
    private var spinnyNode : SKShapeNode?
    private var hpIcon: SKSpriteNode?
    private var jetNode: SKSpriteNode?
    private var bossNode: SKSpriteNode?
    private var bulletNode: SKSpriteNode?
    private var boss1Node: SKSpriteNode?
    private var bbulletNode:SKSpriteNode?
    
    private var finishButton: SKSpriteNode?
    
    private var isLost: Bool?
    
    var gameViewControllerDelegate:GameViewControllerDelegate?
    
    var bossX: CGFloat = 0.0
    var bossY: CGFloat = 0.0
    var bossNumber = 0
    var bossHP = 30
    var score = 0
    var jet_hp = 0
    var physic:SKPhysicsBody?
    private var isBoss: Bool?
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
    
    func playBgm(){
        // For background audio (playing continuously)
        SKTAudio.sharedInstance().playBackgroundMusic("game_music.mp3") // Start the music
        //        SKTAudio.sharedInstance().pauseBackgroundMusic() // Pause the music
        //        SKTAudio.sharedInstance().resumeBackgroundMusic() // Resume the music
        
        // For short sounds
        //        SKTAudio.sharedInstance().playSoundEffect("sound.wav") // Play the sound once
    }
    
    func stopBgm(){
        SKTAudio.sharedInstance().pauseBackgroundMusic() // Pause the music
    }
    
    func resumeBgm(){
        SKTAudio.sharedInstance().resumeBackgroundMusic()
    }
    
    func setGame(){
        playBgm()
        self.bossNumber = 0
        self.score = 0
        self.jet_hp = 5
        
        if let gameLifeCount = self.userData?.value(forKey: "gameLifeCount") {
            print("gameLifeCount is :\(gameLifeCount)")
            self.jet_hp = gameLifeCount as! Int
        }
        
        self.bossHP = 30
        self.isLost=false
        self.isBoss=false
        self.hp?.text = "X\(self.jet_hp)"
        self.scoreBoard?.text="Your Score is: \(self.score)"
        self.label?.text="STAR WAR"
        self.boss1Node?.physicsBody = nil
        self.boss1Node?.zPosition=1
        self.boss1Node?.isHidden=true
        self.boss1Node?.physicsBody?.isDynamic=false
        let rotateAction = SKAction.rotate(toAngle:0, duration: 0)
        let actionMove = SKAction.move(to: CGPoint(x: (self.bossX), y: (self.bossY)),
                                       duration: TimeInterval(0))
        self.boss1Node?.run(SKAction.sequence([actionMove,rotateAction]))
    }
    
    override func didMove(to view: SKView) {
        
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
        self.hp = self.childNode(withName: "//hpLabel") as? SKLabelNode
        self.bossNode = self.childNode(withName: "boss") as? SKSpriteNode
        self.bulletNode = self.childNode(withName: "bullet") as? SKSpriteNode
        self.hpIcon = self.childNode(withName: "hp1") as? SKSpriteNode
        self.bbulletNode = self.childNode(withName: "bbullet") as? SKSpriteNode
        self.bulletNode?.zPosition=1
        self.bulletNode?.isHidden=true
        self.bulletNode?.physicsBody?.isDynamic=false
        self.bbulletNode?.zPosition=1
        self.bbulletNode?.isHidden=true
        self.bbulletNode?.physicsBody?.isDynamic=false
        //        self.bossNode = self.childNode(withName: "bullet") as? SKSpriteNode
        self.bossNode?.zPosition=1
        self.bossNode?.isHidden=true
        self.bossNode?.physicsBody?.isDynamic=false
        self.hpIcon?.zPosition=1
        self.hpIcon?.isHidden=false
        self.hpIcon?.physicsBody?.isDynamic=false
        self.boss1Node = self.childNode(withName: "boss1") as? SKSpriteNode
        self.physic = self.boss1Node?.physicsBody
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
        
        if let hp = self.hp {
            hp.alpha = 0.0
            hp.run(SKAction.fadeIn(withDuration: 2.0))
            hp.zPosition=1
            hp.fontSize=32
            hp.text = "X\(jet_hp)"
        }
        
        if let label = self.scoreBoard {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
            label.zPosition=1
            label.fontSize=40
            label.text="Your Score is: \(score)"
        }
        
        self.bossX = (self.boss1Node?.position.x)!
        self.bossY = (self.boss1Node?.position.y)!
        setGame()
        
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
                let actionMove = SKAction.move(to: CGPoint(x: n.position.x, y: size.height),
                                               duration: TimeInterval(actualDuration))
                let actionMoveDone = SKAction.removeFromParent()
                n.run(SKAction.sequence([actionMove, actionMoveDone]))
                self.addChild(n)
            }
        }
    }
    func addBBullet(){
        if (!self.isLost! && self.isBoss!){
            if let n = self.bbulletNode?.copy() as! SKSpriteNode? {
                n.isHidden=false
                n.physicsBody?.isDynamic=true
                n.position.x=(self.boss1Node?.position.x)!
                n.position.y=(self.boss1Node?.position.y)!
                let actualDuration = CGFloat(1.0)
                // Create the actions
                let actionMove = SKAction.move(to: CGPoint(x: tan(self.boss1Node!.zRotation)*size.height, y: -size.height),
                                               duration: TimeInterval(actualDuration))
                let actionMoveDone = SKAction.removeFromParent()
                n.run(SKAction.sequence([actionMove, actionMoveDone]))

                self.addChild(n)
            }
        }
    }
    
    func addEnemy(){
        if(self.score >= 2) {
            if(self.bossNumber == 0){
                self.bossNumber = 1
                self.isBoss = true
                addBoss()
            }
        }
        if (!self.isLost! && !self.isBoss!){
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
        
        // Add the monster to the scene
//        addChild(enemy)
    }
    func addBoss(){
        if (!self.isLost!){
            self.boss1Node?.position.x = CGFloat(self.bossX)
            self.boss1Node?.position.y = CGFloat(self.bossY)
            self.boss1Node?.isHidden = false
            self.boss1Node?.physicsBody?.isDynamic = true
            
            let actualDuration = CGFloat(1.5)
            
            let actionMove = SKAction.move(to: CGPoint(x: ((self.boss1Node?.position.x)!), y: ((self.boss1Node?.position.y)!)-418),
                                           duration: TimeInterval(actualDuration))
            let rotateAction = SKAction.rotate(toAngle: .pi / 4, duration: 2)
            let rotateAction2 = SKAction.rotate(toAngle: -.pi / 4, duration: 2)
            let repeatRotation = SKAction.repeatForever(SKAction.sequence([ rotateAction,rotateAction2]))
            run(SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.run(addBBullet),
                    SKAction.wait(forDuration: 0.4)
                    ])
            ),withKey: "stopB")
            let addbody = SKAction.run {
                self.boss1Node?.physicsBody = self.physic
            }
            self.bossNode?.zPosition = 2
            self.boss1Node?.run(SKAction.sequence([actionMove,addbody,repeatRotation]),withKey:"stopR")
            
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
        
//        self.finishButton?.removeFromParent()
        
        if(self.bossNumber == -1){
            if(self.childNode(withName: "jet") == nil){
            addChild((self.jetNode)!)
            self.jetNode?.isHidden=false
            self.jetNode?.physicsBody?.isDynamic=true
            }
            self.boss1Node?.removeAction(forKey: "stopR")
            self.removeAction(forKey: "stopB")
            setGame()
        }
        else if(self.isLost!){
            self.jet_hp -= 1
            if(self.jet_hp>=0){
                addChild((self.jetNode)!)
                self.jetNode?.isHidden=false
                self.label?.text="STAR WAR"
                self.jetNode?.physicsBody?.isDynamic=true
                self.isLost=false
                self.hp?.text = "X\(jet_hp)"
                resumeBgm()
            }
            else{
                addChild((self.jetNode)!)
                self.jetNode?.isHidden=false
                self.jetNode?.physicsBody?.isDynamic=true
                
                self.boss1Node?.removeAction(forKey: "stopR")
                self.removeAction(forKey: "stopB")
                setGame()
            }
//            self.scoreBoard?.isHidden=false
            
        }
//        addChild(self.finishButton!)
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
            if(self.jet_hp >= 1){
                self.label?.text="Touch to revive"
            }
            else {
                self.label?.text="Game Over, Touch to restart"
            }
            self.isLost=true
            SKTAudio.sharedInstance().playSoundEffect("game_over.mp3")
            stopBgm()
//            self.scoreBoard?.isHidden=true
            //        SKAction.stop()
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
            
            SKTAudio.sharedInstance().playSoundEffect("enemy1_down.mp3")
            
            enemy.removeFromParent()
            self.score+=1
            self.scoreBoard?.text="Your Score is: \(self.score)"
            //        SKAction.stop()
        }
    }
    func hitBoss(bullet: SKSpriteNode, boss: SKSpriteNode) {
        if(boss.physicsBody!.isDynamic&&bullet.physicsBody!.isDynamic){
            print("hit")
            bullet.removeFromParent()
            let x = bullet.position.x
            let y = bullet.position.y+50
            let boom = SKSpriteNode(imageNamed: "boom")
            boom.size = CGSize(width:bullet.size.width,height:bullet.size.height)
            boom.position = CGPoint(x: x, y: y)
            self.addChild(boom)
            boom.run(SKAction.fadeOut(withDuration: 2))
            boom.zPosition=3
            self.bossHP -= 1
            self.score += 1
            self.scoreBoard?.text="Your Score is: \(self.score)"
            if(self.bossHP == 0){
                bossDefeat(bullet:bullet, boss:boss)
            }
            SKTAudio.sharedInstance().playSoundEffect("enemy1_down.mp3")
            }
    }
    func bossDefeat(bullet: SKSpriteNode,boss: SKSpriteNode){
        SKTAudio.sharedInstance().playSoundEffect("enemy3_down.mp3")
        let x = boss.position.x
        let y = boss.position.y
        let boom = SKSpriteNode(imageNamed: "boom")
        boom.size = CGSize(width:bullet.size.width,height:bullet.size.height)
        boom.zPosition=3
        boom.position = CGPoint(x: x, y: y)
        self.addChild(boom)
        boom.run(SKAction.fadeOut(withDuration: 2))
        let n = boom.copy() as! SKSpriteNode
        n.position = CGPoint(x: x-50, y: y+40)
        self.addChild(n)
        n.run(SKAction.fadeOut(withDuration: 2))
        let n2 = boom.copy() as! SKSpriteNode
        n2.position = CGPoint(x: x+60, y: y-80)
        self.addChild(n2)
        n2.run(SKAction.fadeOut(withDuration: 2))
        let n3 = boom.copy() as! SKSpriteNode
        n3.position = CGPoint(x: x, y: y-60)
        self.addChild(n3)
        n3.run(SKAction.fadeOut(withDuration: 2))
        let actionMove = SKAction.move(to: CGPoint(x: (self.bossX), y: (self.bossY)),
                                       duration: TimeInterval(0))
        boss.run(SKAction.sequence([SKAction.wait(forDuration: 0.5), actionMove]))
        
        self.bossNumber = -1
        self.isBoss = false
        self.label?.text = "You Won! Touch to replay"
        self.isLost=true
        stopBgm()
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
        if contact.bodyA.node?.name == "bullet"{
            if contact.bodyB.node?.name == "boss1"
            {
                hitBoss(bullet: contact.bodyA.node as! SKSpriteNode, boss: contact.bodyB.node as! SKSpriteNode)
            }
        }
        if contact.bodyB.node?.name == "bullet"{
            if contact.bodyA.node?.name == "boss1"
            {
                hitBoss(bullet: contact.bodyB.node as! SKSpriteNode, boss: contact.bodyA.node as! SKSpriteNode)
            }
        }
        if contact.bodyB.node?.name == "bbulet"{
            if contact.bodyA.node?.name == "jet"
            {
                crash(jet: contact.bodyA.node as! SKSpriteNode, enemy: contact.bodyB.node as! SKSpriteNode)
            }
        }
        if contact.bodyA.node?.name == "jet"{
            if contact.bodyB.node?.name == "bbullet"
            {
                crash(jet: contact.bodyA.node as! SKSpriteNode, enemy: contact.bodyB.node as! SKSpriteNode)
            }
        }
        if contact.bodyA.node?.name == "bullet"{
            if contact.bodyB.node?.name == "bbullet"
            {
                contact.bodyA.node?.removeFromParent()
                contact.bodyB.node?.removeFromParent()
            }
        }
        if contact.bodyB.node?.name == "bbullet"{
            if contact.bodyA.node?.name == "bullet"
            {
                contact.bodyA.node?.removeFromParent()
                contact.bodyB.node?.removeFromParent()
            }
        }
        if contact.bodyA.node?.name == "bullet"{
            if contact.bodyB.node?.name == "boss1"
            {
                contact.bodyA.node?.removeFromParent()
            }
        }
        if contact.bodyB.node?.name == "bullet"{
            if contact.bodyA.node?.name == "boss1"
            {
                contact.bodyB.node?.removeFromParent()
            }
        }
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
}