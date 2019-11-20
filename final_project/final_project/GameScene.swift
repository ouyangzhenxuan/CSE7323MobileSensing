//
//  GameScene.swift
//  final_project
//
//  Created by Yu Chen on 11/8/19.
//  Copyright © 2019 5324. All rights reserved.
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

class GameScene: SKScene,ControlInputDelegate,SKPhysicsContactDelegate{
    
    // MARK: Machine Learning part
    let theAction = ActionPredict.sharedInstance
    // ML part
    
    var left:Bool = false
    var right:Bool = false
    var jump: Bool = false
    var action: Bool = false
    var inventory1: SKSpriteNode?
    func follow(command: String?) {
        switch (command!){
        case ("left"):
            self.left = true
        case ("right"):
            self.right = true
        case ("A"):
            actionJump()
        case ("B"):
//            actionJump()
            theAction.actionBegin()
            DispatchQueue.main.asyncAfter(deadline: .now()+1.5, execute: {
                print("delay 1.5s : \(self.theAction.getPredictedAction())")
                if(self.theAction.getPredictedAction() == "droppingdown"){
                    self.actionJump()
                }
            })
        case "stop right","stop left":
            self.left = false;
            self.right = false;
        default:
            print("otro boton \(String(describing: command))")
            
            
        }
    }
    
    // start the jump action one time
    func actionJump(){
        if(!self.jump){
            self.jump = true
            let jumpUpAction = SKAction.moveBy(x: 0, y:50, duration:0.2)
            let stop = SKAction.run {
                self.jump = false
            }
            self.player?.run(SKAction.sequence([jumpUpAction,stop]))
        }
    }
    
    var player: SKSpriteNode?
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    var touchControlNode : TouchInputNode?
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        setupControls(camera: camera!, scene: self)
        self.player = childNode(withName: "Robin") as! SKSpriteNode
        self.player?.physicsBody?.restitution = 0.0
        
        for node in self.children{
            if(node.name == "map"){
                if let map:SKTileMapNode = node as? SKTileMapNode{
                    giveTileMapPhysicsBody(map: map)
                    map.removeFromParent()
                }
                break
            }
        }
    }
    
    func setupControls(camera : SKCameraNode, scene: SKScene) {
        
        touchControlNode = TouchInputNode(frame: scene.frame)
        touchControlNode?.inputDelegate = self
        touchControlNode?.position = CGPoint.zero
        
        
        camera.addChild(touchControlNode!)
    }
    
    func giveTileMapPhysicsBody(map: SKTileMapNode )
    {
     
        let tileMap = map
        
        let tileSize = tileMap.tileSize
        
        let halfWidth = CGFloat(tileMap.numberOfColumns) / 2 * tileSize.width
        let halfHeight = CGFloat(tileMap.numberOfRows) / 2 * tileSize.height
        
        for col in 0..<tileMap.numberOfColumns {
            
            for row in 0..<tileMap.numberOfRows {
                
                if let tileDefinition = tileMap.tileDefinition(atColumn: col, row: row)
                    
                {
                    
                    let tileArray = tileDefinition.textures
                    let tileTexture = tileArray[0]
                    let x = CGFloat(col) * tileSize.width - halfWidth
                    let y = CGFloat(row) * tileSize.height - halfHeight
                    
                    let tileNode = SKSpriteNode(texture:tileTexture)
                    
                    tileNode.position = CGPoint(x: x, y: y)
                    tileNode.physicsBody = SKPhysicsBody(texture: tileTexture, size: CGSize(width: (tileTexture.size().width), height: (tileTexture.size().height )))
                    tileNode.physicsBody?.linearDamping = 60.0
                    tileNode.physicsBody?.affectedByGravity = false
                    tileNode.physicsBody?.allowsRotation = false
                    tileNode.physicsBody?.isDynamic = false
                    tileNode.physicsBody?.friction = 1
                    tileNode.physicsBody?.restitution = 0.0
                    self.addChild(tileNode)
                    
                    
                }
            }
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        if(self.left){
            if let player = self.player{
                player.position.x = (self.player?.position.x)!-2
                player.texture = SKTexture(imageNamed: "robin_back")
            }
        }
        else if(self.right){
            if let player = self.player{
                player.position.x = (self.player?.position.x)!+2
                player.texture = SKTexture(imageNamed: "robin")
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact){
        if contact.bodyA.categoryBitMask == 1 && contact.bodyB.categoryBitMask == 2 {
            if let object = contact.bodyB.node as? SKSpriteNode{
                touchControlNode?.setinventory1(tex: object.texture!)
                object.removeFromParent()
            }
        }
            
    }
    
}
