//
//  MainMenu.swift
//  final_project
//
//  Created by Zhenxuan Ouyang on 12/14/19.
//  Copyright © 2019 5324. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenu: SKScene{
    var buttonPlay: MSButtonNode!
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        
        /* Set UI connections */
        buttonPlay = self.childNode(withName: "buttonPlay") as! MSButtonNode
        buttonPlay.selectedHandler = {
            self.loadGame()
        }
    }
    func loadGame() {
        /* 1) Grab reference to our SpriteKit view */
        guard let skView = self.view as SKView? else {
            print("Could not get Skview")
            return
        }
        
        /* 2) Load Game scene */
        guard let scene = GameScene(fileNamed:"GameScene") else {
            print("Could not make GameScene, check the name is spelled correctly")
            return
        }
        
        /* 3) Ensure correct aspect mode */
        scene.scaleMode = .aspectFill
        
        /* Show debug */
//        skView.showsPhysics = true
//        skView.showsDrawCount = true
//        skView.showsFPS = true
        
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        /* 4) Start game scene */
        skView.presentScene(scene, transition: SKTransition.fade(withDuration: 1))
    }
}

