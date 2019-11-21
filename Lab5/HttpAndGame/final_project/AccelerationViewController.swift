//
//  AccelerationViewController.swift
//  final_project
//
//  Created by Zhenxuan Ouyang on 11/21/19.
//  Copyright © 2019 5324. All rights reserved.
//

import UIKit
import CoreMotion
import Foundation

class AccelerationViewController: UIViewController {

    @IBOutlet weak var xdata: UILabel!
    @IBOutlet weak var ydata: UILabel!
    @IBOutlet weak var zdata: UILabel!
    
    var motion = CMMotionManager()
    let motionOperationQueue = OperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.myAcceleration()
        // Do any additional setup after loading the view.
    }
    
    
    func myAcceleration(){
        motion.accelerometerUpdateInterval = 0.2
        motion.startAccelerometerUpdates(to: OperationQueue.main, withHandler: {(data, error) in
            if let theData = data{
                self.view.reloadInputViews()
                let x = theData.acceleration.x
                let y = theData.acceleration.y
                let z = theData.acceleration.z
                self.xdata.text = String(format: "%.2f", x)
                self.ydata.text = String(format: "%.2f", y)
                self.zdata.text = String(format: "%.2f", z)
                
            }
        })
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension Double{
    func format(f: String) -> String{
        return String(format: "%\(f)f", self)
    }
}
