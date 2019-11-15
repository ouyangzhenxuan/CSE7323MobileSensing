//
//  TouchInputNode.swift
//  final_project
//
//  Created by Yu Chen on 11/12/19.
//  Copyright © 2019 5324. All rights reserved.
//

import SpriteKit

class TouchInputNode : SKSpriteNode {
    
    let theAction = ActionPredict.sharedInstance
    
    var alphaUnpressed:CGFloat = 0.7
    var alphaPressed:CGFloat   = 1.0
    
    var pressedButtons = [SKSpriteNode]()
    
    let buttonDirLeft   = SKSpriteNode(imageNamed: "leftbutton")
    let buttonDirRight  = SKSpriteNode(imageNamed: "rightbutton")
    
    let buttonA = SKSpriteNode(imageNamed: "jumpbutton")
    let buttonB = SKSpriteNode(imageNamed: "actionbutton")
    
    let inventory1 =  SKSpriteNode(imageNamed: "inventory")
    var inventory11 = SKSpriteNode(imageNamed: "inventory")
    let inventory2 =  SKSpriteNode(imageNamed: "inventory")
    let inventory3 =  SKSpriteNode(imageNamed: "inventory")
    let inventory4 =  SKSpriteNode(imageNamed: "inventory")
    let inventory5 =  SKSpriteNode(imageNamed: "inventory")
    let inventory6 =  SKSpriteNode(imageNamed: "inventory")

    var inputDelegate : ControlInputDelegate?
    
    
    init(frame: CGRect) {
        
        
        super.init(texture: nil, color: UIColor.clear, size: frame.size)
        
        setupControls(size: frame.size)
        isUserInteractionEnabled = true
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupControls(size : CGSize) {
        

        addButton(button: buttonDirLeft,
                  position: CGPoint(x: -(size.width / 3 ) - 50, y: -size.height / 4),
                  name: "left",
                  scale: 0.8)
        addButton(button: buttonDirRight,
                  position: CGPoint(x: -(size.width / 3 ) + 25, y: -size.height / 4),
                  name: "right",
                  scale: 0.8)
        addButton(button: buttonA,
                  position: CGPoint(x: (size.width / 3 ) + 50, y: -size.height / 4),
                  name: "A",
                  scale: 0.80)
        addButton(button: buttonB,
                  position: CGPoint(x: (size.width / 3 ) - 20, y: -size.height / 4),
                  name: "B",
                  scale: 0.13)
        addButton(button: inventory1,
                  position: CGPoint(x: -(size.width / 3 ) + 105, y: -size.height / 4-10),
                  name: "inventory1",
                  scale: 0.13)
        addButton(button: inventory11,
        position: CGPoint(x: -(size.width / 3 ) + 105, y: -size.height / 4-10),
        name: "inventory11",
        scale: 0.13)
        addButton(button: inventory2,
        position: CGPoint(x: -(size.width / 3 ) + 140, y: -size.height / 4-10),
        name: "inventory2",
        scale: 0.13)
        addButton(button: inventory3,
        position: CGPoint(x: -(size.width / 3 ) + 175, y: -size.height / 4-10),
        name: "inventory3",
        scale: 0.13)
        addButton(button: inventory4,
        position: CGPoint(x: -(size.width / 3 ) + 210, y: -size.height / 4-10),
        name: "inventory4",
        scale: 0.13)
        addButton(button: inventory5,
        position: CGPoint(x: -(size.width / 3 ) + 245, y: -size.height / 4-10),
        name: "inventory5",
        scale: 0.13)
        addButton(button: inventory6,
        position: CGPoint(x: -(size.width / 3 ) + 280, y: -size.height / 4-10),
        name: "inventory6",
        scale: 0.13)
    }
    
    func addButton(button: SKSpriteNode, position: CGPoint, name: String, scale: CGFloat){
        button.position = position
        button.setScale(scale)
        button.name = name
        button.zPosition = 10
        button.alpha = alphaUnpressed
        self.addChild(button)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            
            let location = t.location(in: parent!)
            // for all 4 buttons
            for button in [ buttonDirLeft, buttonDirRight, buttonA, buttonB] {
                // I check if they are already registered in the list
                if button.contains(location) && pressedButtons.index(of: button) == nil {
                    pressedButtons.append(button)
                    if ((inputDelegate) != nil){
                        inputDelegate?.follow(command: button.name!)
                    }
//                    if button.name == "A" {
                    
//                    }
                    
                }
                if pressedButtons.index(of: button) == nil {
                    button.alpha = alphaUnpressed
                }
                else {
                    button.alpha = alphaPressed
                }
            }
            
        }
        
    }
    
    func setinventory1(tex:SKTexture){
        inventory11.texture = tex
        inventory11.zPosition = 3
        inventory1.zPosition = 1
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            
            let location = t.location(in: parent!)
            let previousLocation = t.previousLocation(in: parent!)
            for button in [ buttonDirLeft, buttonDirRight, buttonA] {
                // if I get off the button where my finger was before
                if button.contains(previousLocation)
                    && !button.contains(location) {
                    // I remove it from the list
                    let index = pressedButtons.index(of: button)
                    if index != nil {
                        pressedButtons.remove(at: index!)
                        
                        if ((inputDelegate) != nil){
                            inputDelegate?.follow(command: "cancel \(String(describing: button.name!))")
                        }
                        
                    }
                }
                    // if I get on the button where I wasn't previously
                else if !button.contains(previousLocation)
                    && button.contains(location)
                    && pressedButtons.index(of: button) == nil {
                    // I add it to the list
                    pressedButtons.append(button)
                    if ((inputDelegate) != nil){
                        inputDelegate?.follow(command: button.name!)
                    }
                }
                if pressedButtons.index(of: button) == nil {
                    button.alpha = alphaUnpressed
                }
                else {
                    button.alpha = alphaPressed
                }
            }
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        touchUp(touches: touches, withEvent: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        touchUp(touches: touches, withEvent: event)
        
    }
    
    func touchUp(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        for touch in touches! {
            let location = touch.location(in: parent!)
            let previousLocation = touch.previousLocation(in: parent!)
            for button in [buttonDirLeft, buttonDirRight, buttonA, buttonB] {
                if button.contains(location) {
                    let index = pressedButtons.index(of: button)
                    if index != nil {
                        pressedButtons.remove(at: index!)
                        if ((inputDelegate) != nil){
                            inputDelegate?.follow(command: "stop \(String(describing: button.name!))")
                        }
                        
                        print(theAction.getPredictedAction())
                        
                    }
                }
                else if (button.contains(previousLocation)) {
                    let index = pressedButtons.index(of: button)
                    if index != nil {
                        pressedButtons.remove(at: index!)
                        if ((inputDelegate) != nil){
                            inputDelegate?.follow(command: "stop \(String(describing: button.name!))")
                        }
                        
                    }
                }
                if pressedButtons.index(of: button) == nil {
                    button.alpha = alphaUnpressed
                }
                else {
                    button.alpha = alphaPressed
                }
            }
        }
        
    }
}

protocol ControlInputDelegate {
    func follow(command: String?)
//    func actionBegin()
//    func actionDone()
}

