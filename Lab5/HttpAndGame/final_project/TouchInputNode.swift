//
//  TouchInputNode.swift
//  final_project
//
//  Created by Yu Chen on 11/12/19.
//  Copyright © 2019 5323. All rights reserved.
//

import SpriteKit

// class that set up on screen ui control
class TouchInputNode : SKSpriteNode {
    // initial variables
    var alphaunpressed:CGFloat = 0.7
    var alphapressed:CGFloat   = 1.0
    
    var pressedbuttons = [SKSpriteNode]()
    
    let buttondirleft   = SKSpriteNode(imageNamed: "leftbutton")
    let buttondirright  = SKSpriteNode(imageNamed: "rightbutton")
    
    let buttonA = SKSpriteNode(imageNamed: "jumpbutton")
    let buttonB = SKSpriteNode(imageNamed: "actionbutton")
    let motionbutton = SKSpriteNode(imageNamed: "motion")
    let motionbutton2 = SKSpriteNode(imageNamed: "motion")
    
    let inventory1 =  SKSpriteNode(imageNamed: "inventory")
    let inventory2 =  SKSpriteNode(imageNamed: "inventory")
    let inventory3 =  SKSpriteNode(imageNamed: "inventory")
    let inventory4 =  SKSpriteNode(imageNamed: "inventory")
    let inventory5 =  SKSpriteNode(imageNamed: "inventory")
    let inventory6 =  SKSpriteNode(imageNamed: "inventory")
    var inventory1_item = SKSpriteNode(imageNamed: "inventory")
    var inventory2_item = SKSpriteNode(imageNamed: "inventory")
    var inventory3_item = SKSpriteNode(imageNamed: "inventory")
    var inventory4_item = SKSpriteNode(imageNamed: "inventory")
    var inventory5_item = SKSpriteNode(imageNamed: "inventory")
    var inventory6_item = SKSpriteNode(imageNamed: "inventory")
    
    var inventory: [SKSpriteNode] = []
    var inventory_background:[SKSpriteNode] = []
    var items:[Bool] = [false,false,false,false,false,false]
    var selected:Int = -1
    var item_category:[Int] = [0,0,0,0,0,0]
    

    var inputDelegate : ControlInputDelegate?
    
    // MARK: Init Function
    init(frame: CGRect) {
        
        
        super.init(texture: nil, color: UIColor.clear, size: frame.size)
        
        setupControls(size: frame.size)
        isUserInteractionEnabled = true
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Create Buttons
    // function that creates all buttons with their position and size
    func setupControls(size : CGSize) {
        

        addButton(button: buttondirleft,
                  position: CGPoint(x: -(size.width / 3 ) - 50, y: -size.height / 3),
                  name: "left",
                  scale: 0.8)
        addButton(button: buttondirright,
                  position: CGPoint(x: -(size.width / 3 ) + 25, y: -size.height / 3),
                  name: "right",
                  scale: 0.8)
        addButton(button: buttonA,
                  position: CGPoint(x: (size.width / 3 ) + 50, y: -size.height / 3),
                  name: "A",
                  scale: 0.80)
        addButton(button: buttonB,
                  position: CGPoint(x: (size.width / 3 ) - 20, y: -size.height / 4),
                  name: "B",
                  scale: 0.80)
        addButton(button: motionbutton,
        position: CGPoint(x: (size.width / 3 ) + 50, y: -size.height / 3 + 65),
        name: "M",
        scale: 0.60)
        
        addButton(button: motionbutton2,
                  position: CGPoint(x: (size.width / 3 ) + 50, y: -size.height / 3 + 120),
                  name: "T",
                  scale: 0.60)
        
        addButton(button: inventory1,
                  position: CGPoint(x: -(size.width / 3 ) + 105, y: -size.height / 3),
                  name: "inventory1",
                  scale: 0.13)
        addButton(button: inventory2,
        position: CGPoint(x: -(size.width / 3 ) + 140, y: -size.height / 3),
        name: "inventory2",
        scale: 0.13)
        addButton(button: inventory3,
        position: CGPoint(x: -(size.width / 3 ) + 175, y: -size.height / 3),
        name: "inventory3",
        scale: 0.13)
        addButton(button: inventory4,
        position: CGPoint(x: -(size.width / 3 ) + 210, y: -size.height / 3),
        name: "inventory4",
        scale: 0.13)
        addButton(button: inventory5,
        position: CGPoint(x: -(size.width / 3 ) + 245, y: -size.height / 3),
        name: "inventory5",
        scale: 0.13)
        addButton(button: inventory6,
        position: CGPoint(x: -(size.width / 3 ) + 280, y: -size.height / 3),
        name: "inventory6",
        scale: 0.13)
        setInventoryButton(button: inventory1_item,
        position: CGPoint(x: -(size.width / 3 ) + 105, y: -size.height / 3),
        name: "inventory1_item",
        scale: 0.13)
        setInventoryButton(button: inventory2_item,
        position: CGPoint(x: -(size.width / 3 ) + 140, y: -size.height / 3),
        name: "inventory2_item",
        scale: 0.13)
        setInventoryButton(button: inventory3_item,
        position: CGPoint(x: -(size.width / 3 ) + 175, y: -size.height / 3),
        name: "inventory3_item",
        scale: 0.13)
        setInventoryButton(button: inventory4_item,
        position: CGPoint(x: -(size.width / 3 ) + 210, y: -size.height / 3),
        name: "inventory4_item",
        scale: 0.13)
        setInventoryButton(button: inventory5_item,
        position: CGPoint(x: -(size.width / 3 ) + 245, y: -size.height / 3),
        name: "inventory5_item",
        scale: 0.13)
        setInventoryButton(button: inventory6_item,
        position: CGPoint(x: -(size.width / 3 ) + 280, y: -size.height / 3),
        name: "inventory6_item",
        scale: 0.13)
        self.inventory =  [inventory1_item,inventory2_item,inventory3_item,inventory4_item,inventory5_item,inventory6_item]
        self.inventory_background =  [inventory1,inventory2,inventory3,inventory4,inventory5,inventory6]
    }
    
    // function that sets inventory buttons
    func setInventoryButton(button: SKSpriteNode, position: CGPoint, name: String, scale: CGFloat){
        button.position = position
        button.setScale(scale)
        button.name = name
        button.zPosition = 11
        button.alpha = 0
        self.addChild(button)
    }
    
    // function that sets movement and action buttons
    func addButton(button: SKSpriteNode, position: CGPoint, name: String, scale: CGFloat){
        button.position = position
        button.setScale(scale)
        button.name = name
        button.zPosition = 10
        button.alpha = alphaunpressed
        self.addChild(button)
    }
    
    
    // MARK: Inventory Handlers
    // function to show picked item on the inventory
    func setinventory(tex:SKTexture,category:UInt32) -> Bool{
        var full = false
        for i in 0..<self.items.count{
            if(!self.items[i]){
                self.inventory[i].texture = tex
                self.inventory[i].alpha = 1
                self.inventory[i].setScale(0.10)
                self.items[i] = true
                self.item_category[i] = Int(category)
                full = true
                return full
            }
        }
        return full
    }
    
    // function to select inventory
    func selectInventory(inve_name:String){
        for i in 0..<self.inventory.count{
            if(self.inventory[i].name == inve_name){
                if(self.selected != -1 && self.selected != i){
                    self.inventory_background[i].color = .yellow
                    self.inventory_background[i].colorBlendFactor = 1.0
                    self.inventory_background[i].alpha = 2
                    self.inventory_background[self.selected].colorBlendFactor = 0
                    self.inventory_background[self.selected].alpha = alphaunpressed
                    self.selected = i
                    break
                }
                else if(self.selected == i){
                    self.inventory_background[self.selected].colorBlendFactor = 0
                    self.inventory_background[self.selected].alpha = alphaunpressed
                    self.selected = -1
                    break
                }
                else{
                    self.inventory_background[i].color = .yellow
                    self.inventory_background[i].colorBlendFactor = 1.0
                    self.inventory_background[i].alpha = 2
                    self.selected = i
                    break
                }
            }
        }
    }
    
    // function to return item's category
    func checkItemCategory() -> Int{
        if(self.selected == -1){
            return -1
        }
        return self.item_category[self.selected]
    }
    
    // function to use an item
    func useItem() -> SKSpriteNode{
        var item = SKSpriteNode()
        item.name = ""
        if(self.selected != -1){
            if(self.items[self.selected]){
                    item = SKSpriteNode(texture: self.inventory[self.selected].texture)
                    item.physicsBody = SKPhysicsBody(rectangleOf: (item.texture?.size())!)
                    item.physicsBody?.categoryBitMask = UInt32(self.item_category[self.selected])
                    item.physicsBody?.collisionBitMask = UInt32(self.item_category[self.selected])
                    item.physicsBody?.contactTestBitMask = 1
                    item.name = "item"
                    self.inventory[self.selected].texture = SKTexture(imageNamed: "inventory")
                    self.inventory[self.selected].alpha = 0
                    self.items[self.selected] = false
                    self.item_category[self.selected] = 0
                    self.inventory_background[self.selected].colorBlendFactor = 0
                    self.inventory_background[self.selected].alpha = alphaunpressed
                    self.selected = -1
                    return item
                
            }
        }
        return item
    }
    
    // MARK: Overrite Touch Functions
    // those functions will override touch functions
    // when users touch those buttons, it will call follow functions in gamescene
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            
            let location = t.location(in: parent!)
            // for all 4 buttons
            for button in [ buttondirleft, buttondirright, buttonA,inventory1_item,inventory2_item,inventory3_item,inventory4_item,inventory5_item,inventory6_item,motionbutton,motionbutton2,buttonB] {
                // I check if they are already registered in the list
                if button.contains(location) && pressedbuttons.index(of: button) == nil {
                    pressedbuttons.append(button)
                    if ((inputDelegate) != nil){
                        inputDelegate?.follow(command: button.name!)
                    }
                    
                    
                }
                if pressedbuttons.index(of: button) == nil {
                    if(!self.inventory.contains(button)){
                        button.alpha = alphaunpressed}
                }
                else {
                    if(!self.inventory.contains(button)){
                        button.alpha = alphapressed}
                }
            }
            
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            
            let location = t.location(in: parent!)
            let previousLocation = t.previousLocation(in: parent!)
            for button in [ buttondirleft, buttondirright, buttonA,inventory1_item,inventory2_item,inventory3_item,inventory4_item,inventory5_item,inventory6_item,motionbutton,motionbutton2, buttonB] {
                // if I get off the button where my finger was before
                if button.contains(previousLocation)
                    && !button.contains(location) {
                    // I remove it from the list
                    let index = pressedbuttons.index(of: button)
                    if index != nil {
                        pressedbuttons.remove(at: index!)
                        
                        if ((inputDelegate) != nil){
                            inputDelegate?.follow(command: "cancel \(String(describing: button.name!))")
                        }
                        
                    }
                }
                    // if I get on the button where I wasn't previously
                else if !button.contains(previousLocation)
                    && button.contains(location)
                    && pressedbuttons.index(of: button) == nil {
                    // I add it to the list
                    pressedbuttons.append(button)
                    if ((inputDelegate) != nil){
                        inputDelegate?.follow(command: button.name!)
                    }
                }
                if pressedbuttons.index(of: button) == nil {
                    if(!self.inventory.contains(button)){
                        button.alpha = alphaunpressed}
                }
                else {
                    if(!self.inventory.contains(button)){
                        button.alpha = alphapressed}
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
            for button in [buttondirleft, buttondirright, buttonA,inventory1_item,inventory2_item,inventory3_item,inventory4_item,inventory5_item,inventory6_item,motionbutton,motionbutton2, buttonB] {
                if button.contains(location) {
                    let index = pressedbuttons.index(of: button)
                    if index != nil {
                        pressedbuttons.remove(at: index!)
                        if ((inputDelegate) != nil){
                            inputDelegate?.follow(command: "stop \(String(describing: button.name!))")
                        }
                    }
                }
                else if (button.contains(previousLocation)) {
                    let index = pressedbuttons.index(of: button)
                    if index != nil {
                        pressedbuttons.remove(at: index!)
                        if ((inputDelegate) != nil){
                            inputDelegate?.follow(command: "stop \(String(describing: button.name!))")
                        }
                    }
                }
                if pressedbuttons.index(of: button) == nil {
                    if(!self.inventory.contains(button)){
                        button.alpha = alphaunpressed}
                }
                else {
                    if(!self.inventory.contains(button)){
                        button.alpha = alphapressed}
                }
            }
        }
        
    }
}

// MARK: Protocol Function
// this function will be implemented in gamescene
protocol ControlInputDelegate {
    func follow(command: String?)
}
