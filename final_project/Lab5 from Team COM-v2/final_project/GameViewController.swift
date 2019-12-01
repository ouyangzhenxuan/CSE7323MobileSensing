//
//  GameViewController.swift
//  final_project
//
//  Created by Yu Chen on 11/8/19.
//  Copyright © 2019 5323. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController,GameViewControllerDelegate,GameViewControllerDelegate2 {

    @IBOutlet weak var dismissButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        let portrait_orientation = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(portrait_orientation, forKey: "orientation")
//        if let view = self.view as! SKView? {
//            // Load the SKScene from 'GameScene.sks'
//            if let scene = SKScene(fileNamed: "GameScene") {
//                // Set the scale mode to scale to fit the window
//                scene.scaleMode = .aspectFill
//
//                let gameScene = scene as! GameScene
//                gameScene.gameViewControllerDelegate = self
//                // Present the scene
//                view.presentScene(scene)
//            }
//
//            view.ignoresSiblingOrder = true
//
//            view.showsFPS = true
//            view.showsNodeCount = true
//        }
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene2") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill

                let gameScene = scene as! GameScene2
                gameScene.gameViewControllerDelegate2 = self
                // Present the scene
                view.presentScene(scene)
            }

            view.ignoresSiblingOrder = true

            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func finishGame(inputProperty:String) {
        print("inputProperty is: ",inputProperty)
        self.dismiss(animated: true, completion: nil)
        if let view = self.view as! SKView? {
            view.presentScene(nil);
        }
        self.navigationController?.popViewController(animated: true)
        
    }
}
