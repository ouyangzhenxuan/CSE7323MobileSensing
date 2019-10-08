//
//  ViewController.swift
//  MotionLab
//
//  Created by Zhenxuan Ouyang on 10/8/19.
//  Copyright © 2019 Zhenxuan Ouyang. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {

    let activityManager = CMMotionActivityManager()
    let customQueue = OperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if CMMotionActivityManager.isActivityAvailable(){
            self.activityManager.startActivityUpdates(to: customQueue){
                (activity:CMMotionActivity?) -> Void in
                NSLog("%@", activity!.description)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if CMMotionActivityManager.isActivityAvailable(){
            self.activityManager.stopActivityUpdates()
        }
        super.viewWillDisappear(animated)
    }

}

