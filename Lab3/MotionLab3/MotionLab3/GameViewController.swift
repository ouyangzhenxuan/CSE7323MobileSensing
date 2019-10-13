//
//  GameViewController.swift
//  HKBTCN
//
//  Created by 梅沈潇 on 10/9/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController, GameViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                
                let gameScene = scene as! GameScene
                gameScene.gameViewControllerDelegate = self
                
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
