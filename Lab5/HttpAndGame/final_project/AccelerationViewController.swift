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
    @IBOutlet weak var gx: UILabel!
    @IBOutlet weak var gy: UILabel!
    @IBOutlet weak var gz: UILabel!
    
    @IBOutlet weak var theSum: UILabel!
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
        motion.deviceMotionUpdateInterval = 0.2
        motion.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: {(data, error) in
            if let theData = data{
                self.view.reloadInputViews()
                let x = theData.gravity.x
                let y = theData.gravity.y
                let z = theData.gravity.z
                
                //self.gx.text = String(format: "%.2f", x)
                self.gy.text = String(format: "%.2f", y)
                self.gz.text = String(format: "%.2f", z)
                
                let proj = sqrt(fabs(
                                theData.userAcceleration.x*theData.gravity.x +
                                theData.userAcceleration.y*theData.gravity.y +
                                theData.userAcceleration.z*theData.gravity.z
                                ))
                let transform = CGAffineTransform.init(rotationAngle: .pi/2)
//                let gravPerpendicular =
            
                
                self.gx.text = String(format: "%.2f", proj)
                
                self.gx.text = String(format: "%.2f", (theData.userAcceleration.x-theData.gravity.x)*theData.gravity.x)
                self.gy.text = String(format: "%.2f", (theData.userAcceleration.y-theData.gravity.y)*theData.gravity.y)
                self.gz.text = String(format: "%.2f", (theData.userAcceleration.z-theData.gravity.z)*theData.gravity.z)
                
                self.gx.text = String(format: "%.2f", (theData.userAcceleration.x-theData.gravity.x))
                self.gy.text = String(format: "%.2f", (theData.userAcceleration.y-theData.gravity.y))
                self.gz.text = String(format: "%.2f", (theData.userAcceleration.z-theData.gravity.z))
                
                self.theSum.text = String(format: "%.2f", proj)

                
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
