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
    
    var gameViewControllerDelegate:GameViewControllerDelegate?
    
    private var label : SKLabelNode?
    private var hp: SKLabelNode?
    private var scoreBoard: SKLabelNode?
    private var hpIcon: SKSpriteNode?
    private var jetNode: SKSpriteNode?
    private var minionNode: SKSpriteNode?
    private var bulletNode: SKSpriteNode?
    private var bossNode: SKSpriteNode?
    private var bossbulletNode:SKSpriteNode?
    private var finishButton: SKSpriteNode?
    private var isLost: Bool?
    private var bossX: CGFloat = 0.0
    private var bossY: CGFloat = 0.0
    private var bossNumber = 0
    private var bossHP = 30
    private var score = 0
    private var jet_hp = 0
    private var physic:SKPhysicsBody?
    private var isBoss: Bool?
    private var powerUp:Bool?
    
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
        SKTAudio.sharedInstance().playBackgroundMusic("game_music.mp3")
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
            self.jet_hp = gameLifeCount as! Int
        }
        if let isPowerUp = self.userData?.value(forKey: "powerUp"){
            self.powerUp = isPowerUp as? Bool
        }
        
        self.bossHP = 30
        self.isLost=false
        self.isBoss=false
        self.hp?.text = "X\(self.jet_hp)"
        self.scoreBoard?.text="Your Score is: \(self.score)"
        self.label?.text="STAR WAR"
        self.bossNode?.physicsBody = nil
        self.bossNode?.zPosition=1
        self.bossNode?.isHidden=true
        self.bossNode?.physicsBody?.isDynamic=false
        let rotateAction = SKAction.rotate(toAngle:0, duration: 0)
        let actionMove = SKAction.move(to: CGPoint(x: (self.bossX), y: (self.bossY)),
                                       duration: TimeInterval(0))
        self.bossNode?.run(SKAction.sequence([actionMove,rotateAction]))
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        let background = SKSpriteNode(imageNamed: "sky.jpg")
        background.zPosition=0
        addChild(background)
        self.startMotionUpdates()
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        self.scoreBoard = self.childNode(withName: "//scoreLabel") as? SKLabelNode
        self.hp = self.childNode(withName: "//hpLabel") as? SKLabelNode
        self.minionNode = self.childNode(withName: "boss") as? SKSpriteNode
        self.bulletNode = self.childNode(withName: "bullet") as? SKSpriteNode
        self.hpIcon = self.childNode(withName: "hp1") as? SKSpriteNode
        self.bossbulletNode = self.childNode(withName: "bbullet") as? SKSpriteNode
        self.bossNode = self.childNode(withName: "boss1") as? SKSpriteNode
        self.physic = self.bossNode?.physicsBody
        
//        self.bulletNode?.zPosition=1
//        self.bulletNode?.isHidden=true
//        self.bulletNode?.physicsBody?.isDynamic=false
//        self.bossbulletNode?.zPosition=1
//        self.bossbulletNode?.isHidden=true
//        self.bossbulletNode?.physicsBody?.isDynamic=false
//        self.minionNode?.zPosition=1
//        self.minionNode?.isHidden=true
//        self.minionNode?.physicsBody?.isDynamic=false
//        self.hpIcon?.zPosition=1
//        self.hpIcon?.isHidden=false
//        self.hpIcon?.physicsBody?.isDynamic=false
        
        
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
    
        
        if let label = self.bulletNode {
            label.zPosition=1
            label.isHidden=true
            label.physicsBody?.isDynamic=false
        }
        
        if let label = self.bossbulletNode {
            label.zPosition=1
            label.isHidden=true
            label.physicsBody?.isDynamic=false
        }
        
        if let label = self.minionNode {
            label.zPosition=1
            label.isHidden=true
            label.physicsBody?.isDynamic=false
        }
        
        if let label = self.hpIcon {
            label.zPosition=1
            label.isHidden=true
            label.physicsBody?.isDynamic=false
        }
        
        ////////////////////
        
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
        
        self.bossX = (self.bossNode?.position.x)!
        self.bossY = (self.bossNode?.position.y)!
        setGame()
        
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
    
//    func addBullet(){
//        if (!self.isLost!){
//            if let n = self.bulletNode?.copy() as! SKSpriteNode? {
//                n.isHidden=false
//                n.physicsBody?.isDynamic=true
//                n.position.x=(self.jetNode?.position.x)!
//                let actualDuration = CGFloat(1.0)
//
//                // Create the actions
//                let actionMove = SKAction.move(to: CGPoint(x: n.position.x, y: size.height),
//                                               duration: TimeInterval(actualDuration))
//                let actionMoveDone = SKAction.removeFromParent()
//                n.run(SKAction.sequence([actionMove, actionMoveDone]))
//                self.addChild(n)
//            }
//        }
//    }
    
    func addBullet(){
        if (!self.isLost!){
            if(self.powerUp!){
                if let n = self.bulletNode?.copy() as! SKSpriteNode? {
                    n.isHidden=false
                    n.physicsBody?.isDynamic=true
                    n.position.x=(self.jetNode?.position.x)! - 10
                    let actualDuration = CGFloat(1.0)
                    
                    // Create the actions
                    let actionMove = SKAction.move(to: CGPoint(x: n.position.x, y: size.height),
                                                   duration: TimeInterval(actualDuration))
                    let actionMoveDone = SKAction.removeFromParent()
                    n.run(SKAction.sequence([actionMove, actionMoveDone]))
                    self.addChild(n)
                }
                if let m = self.bulletNode?.copy() as! SKSpriteNode? {
                    m.isHidden=false
                    m.physicsBody?.isDynamic=true
                    m.position.x=(self.jetNode?.position.x)! + 10
                    let actualDuration = CGFloat(1.0)
                    
                    // Create the actions
                    let actionMove = SKAction.move(to: CGPoint(x: m.position.x, y: size.height),
                                                   duration: TimeInterval(actualDuration))
                    let actionMoveDone = SKAction.removeFromParent()
                    m.run(SKAction.sequence([actionMove, actionMoveDone]))
                    self.addChild(m)
                }
            }
            else{
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
    }
    
    func addBossBullet(){
        if (!self.isLost! && self.isBoss!){
            if let n = self.bossbulletNode?.copy() as! SKSpriteNode? {
                n.isHidden=false
                n.physicsBody?.isDynamic=true
                n.position.x=(self.bossNode?.position.x)!
                n.position.y=(self.bossNode?.position.y)!
                let actualDuration = CGFloat(1.0)
                // Create the actions
                let actionMove = SKAction.move(to: CGPoint(x: tan(self.bossNode!.zRotation)*size.height, y: -size.height),
                                               duration: TimeInterval(actualDuration))
                let actionMoveDone = SKAction.removeFromParent()
                n.run(SKAction.sequence([actionMove, actionMoveDone]))

                self.addChild(n)
            }
        }
    }
    
    func addEnemy(){
        if(self.score >= 3) {
            if(self.bossNumber == 0){
                self.bossNumber = 1
                self.isBoss = true
                addBoss()
            }
        }
        if (!self.isLost! && !self.isBoss!){
            if let n = self.minionNode?.copy() as! SKSpriteNode? {
                n.position.x=random(min: CGFloat((self.minionNode?.size.width)!/2-size.width/2), max: CGFloat(size.width/2-(self.minionNode?.size.width)!/2))
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
    func addBoss(){
        if (!self.isLost!){
            self.bossNode?.position.x = CGFloat(self.bossX)
            self.bossNode?.position.y = CGFloat(self.bossY)
            self.bossNode?.isHidden = false
            self.bossNode?.physicsBody?.isDynamic = true
            
            let actualDuration = CGFloat(1.5)
            
            let actionMove = SKAction.move(to: CGPoint(x: ((self.bossNode?.position.x)!), y: ((self.bossNode?.position.y)!)-418),
                                           duration: TimeInterval(actualDuration))
            let rotateAction = SKAction.rotate(toAngle: .pi / 4, duration: 2)
            let rotateAction2 = SKAction.rotate(toAngle: -.pi / 4, duration: 2)
            let repeatRotation = SKAction.repeatForever(SKAction.sequence([ rotateAction,rotateAction2]))
            run(SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.run(addBossBullet),
                    SKAction.wait(forDuration: 0.4)
                    ])
            ),withKey: "stopB")
            let addbody = SKAction.run {
                self.bossNode?.physicsBody = self.physic
            }
            self.minionNode?.zPosition = 2
            self.bossNode?.run(SKAction.sequence([actionMove,addbody,repeatRotation]),withKey:"stopR")
            
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        if(self.bossNumber == -1){
            if(self.childNode(withName: "jet") == nil){
            addChild((self.jetNode)!)
            self.jetNode?.isHidden=false
            self.jetNode?.physicsBody?.isDynamic=true
            }
            self.bossNode?.removeAction(forKey: "stopR")
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
                
                self.bossNode?.removeAction(forKey: "stopR")
                self.removeAction(forKey: "stopB")
                setGame()
            }
        }
        for t in touches {
            let location = t.location(in: self)
            
            if(self.atPoint(location).name == "finishBtn"){
                gameViewControllerDelegate?.finishGame(inputProperty: "call game view controller method")
            }
        }
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
        if contact.bodyA.node?.name == "jet"{
            if contact.bodyB.node?.name == "boss"
            {
                crash(jet: contact.bodyA.node as! SKSpriteNode, enemy: contact.bodyB.node as! SKSpriteNode)
            }
        }
        if contact.bodyB.node?.name == "jet"{
            if contact.bodyA.node?.name == "boss"
            {
                crash(jet: contact.bodyB.node as! SKSpriteNode, enemy: contact.bodyA.node as! SKSpriteNode)
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

    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    override func willMove(from view: SKView) {
        SKTAudio.sharedInstance().pauseBackgroundMusic() // Pause the music
    }
}
