//
//  SecondChapterScene.swift
//  final_project
//
//  Created by Yu Chen on 11/24/19.
//  Copyright © 2019 5324. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion
import CoreML
import UIKit
protocol ActionDelegate2 {
    func actionBegin()
    func actionDone()
    func updatePredictedAction()
    func getPredictedAction() -> String
}

protocol GameViewControllerDelegate2: class {
    func finishGame(inputProperty:String)
}

// gamescene that manages entire game
class SecondChapterScene: SKScene,SKPhysicsContactDelegate{
    var gameViewControllerDelegate2:GameViewControllerDelegate2?
    
    override func didMove(to view: SKView) {}

}
