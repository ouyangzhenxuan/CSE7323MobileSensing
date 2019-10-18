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

    var gameLifeCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // First set the orientation back to portrait
        let portrait_orientation = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(portrait_orientation, forKey: "orientation")
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                
                // Passing data from gameController to gameScene
                let gameScene = scene as! GameScene
                gameScene.gameViewControllerDelegate = self
                gameScene.userData = NSMutableDictionary()
                gameScene.userData?.setValue(self.gameLifeCount, forKey: "gameLifeCount")
                
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
    
    // finish the game modal and return to ViewController
    func finishGame(inputProperty:String) {
        self.dismiss(animated: true, completion: nil)
        if let view = self.view as! SKView? {
            view.presentScene(nil);
        }
        self.navigationController?.popViewController(animated: true)
        
    }
}
