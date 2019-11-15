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
    func getPredictedAction()->String
}

class GameScene: SKScene,ControlInputDelegate,SKPhysicsContactDelegate{
    
    // MARK: Machine Learning part
    var ringBuffer = RingBuffer()
    let animation = CATransition()
    let motion = CMMotionManager()
    
    let motionOperationQueue = OperationQueue()
    
    var magValue = 0.1
    var isCalibrating = false
    
    var isWaitingForMotionData = true
    
    var modelRf = RandomForestAccel()
    var modelSvm = SVMAccel()
    var modelPipe = PipeAccel()
    
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
            actionJump()
            theAction.actionBegin()
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
    
//    func actionBegin(){
//        print("action begins")
////        _ = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(fire), userInfo: nil, repeats: true)
////        startMotionUpdates()
//        theAction.test()
//    }
//    
//    func actionDone(){
//        print("action done")
//        stopMotionUpdates()
//    }
    
    func returnSomething(name: String) -> String{
        return name
    }
    
    @objc func fire(){
        print("fire")
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
        
//        self.startMotionUpdates()
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
    
    // MARK: ML handler functions
    // MARK: Core Motion Updates
//    func startMotionUpdates(){
//        // some internal inconsistency here: we need to ask the device manager for device
//
//        if self.motion.isDeviceMotionAvailable{
//            self.motion.deviceMotionUpdateInterval = 1.0/200
//            self.motion.startDeviceMotionUpdates(to: motionOperationQueue, withHandler: self.handleMotion )
//        }
//    }
//
//    func stopMotionUpdates(){
//        if self.motion.isDeviceMotionAvailable{
//            self.motion.stopDeviceMotionUpdates()
//        }
//    }
//
//    var handleMotionCount = 0
//    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
//        if let accel = motionData?.userAcceleration {
//            self.ringBuffer.addNewData(xData: accel.x, yData: accel.y, zData: accel.z)
//            handleMotionCount += 1
//            let mag = fabs(accel.x)+fabs(accel.y)+fabs(accel.z)
//            DispatchQueue.main.async{
//                //show magnitude via indicator
////                self.largeMotionMagnitude.progress = Float(mag)/0.2
//            }
//            if handleMotionCount > 100{
//                handleMotionCount = 0
//                // buffer up a bit more data and then notify of occurrence
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
//                    // something large enough happened to warrant
//                    self.largeMotionEventOccurred()
//                })
//                stopMotionUpdates()
//            }
//        }
//    }
//
//    //MARK: Calibration procedure
//    func largeMotionEventOccurred(){
//
//        if(self.isWaitingForMotionData)
//        {
//            self.isWaitingForMotionData = false
//            //predict a label
//            let seq = toMLMultiArray(self.ringBuffer.getDataAsVector())
//            guard let outputRf = try? modelRf.prediction(input: seq) else {
//                fatalError("Unexpected runtime error.")
//            }
//
//            guard let outputSvm = try? modelSvm.prediction(input: seq) else {
//                fatalError("Unexpected runtime error.")
//            }
//
//            guard let outputPipe = try? modelPipe.prediction(input: seq) else {
//                fatalError("Unexpected runtime error.")
//            }
////            displayLabelResponse(outputRf.classLabel)
//            print(outputRf.classLabel)
//            setDelayedWaitingToTrue(2.0)
//            //            displayLabelResponse(outputSvm.classLabel)
//            //            if(outputRf.classLabel == outputSvm.classLabel){
//            //                displayLabelResponse(outputSvm.classLabel)
//            //                // dont predict again for a bit
//            //                setDelayedWaitingToTrue(2.0)
//            //            }
//            //            else{
//            //                displayLabelResponse("Unknown")
//            //                self.isWaitingForMotionData = true
//            //            }
//
//
//
//        }
//    }
//
//    func setDelayedWaitingToTrue(_ time:Double){
//        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: {
//            self.isWaitingForMotionData = true
//        })
//    }
//
//    // convert to ML Multi array
//    // https://github.com/akimach/GestureAI-CoreML-iOS/blob/master/GestureAI/GestureViewController.swift
//    private func toMLMultiArray(_ arr: [Double]) -> MLMultiArray {
//        guard let sequence = try? MLMultiArray(shape:[150], dataType:MLMultiArrayDataType.double) else {
//            fatalError("Unexpected runtime error. MLMultiArray could not be created")
//        }
//        let size = Int(truncating: sequence.shape[0])
//        for i in 0..<size {
//            sequence[i] = NSNumber(floatLiteral: arr[i])
//        }
//        return sequence
//    }
    
}
