//
//  ActionPredict.swift
//  final_project
//
//  Created by Zhenxuan Ouyang on 11/14/19.
//  Copyright © 2019 5324. All rights reserved.
//

import Foundation
import UIKit
import CoreMotion
import CoreML


class ActionPredict: ActionDelegate {
    
    // make it a shared instance, only one instance can exist at an application
    static let sharedInstance = ActionPredict()
    // rewrite the init function to make it invisible to other class
    private init(){}
    
    var ringBuffer = RingBuffer()
    let animation = CATransition()
    let motion = CMMotionManager()
    
    let motionOperationQueue = OperationQueue()
    
    var magValue = 0.1
    var isCalibrating = false
    
    var isWaitingForMotionData = true
    
    var modelRf = RandomForestAccel()
    
    var predictedAction = "Nothing now!"
    var isPredicting = false
    
    // MARK: action begins and finishes
    
    func actionBegin() {
        print("action begin")
        self.isPredicting = true
        startMotionUpdates()
    }
    
    func actionDone() {
        print("action done")
        stopMotionUpdates()
        self.isPredicting = false
    }
    
    func updatePredictedAction() {
//        print("get predicted action")
        if self.isPredicting == true{
            self.predictedAction = "It's still predicting right now, the result isn't available"
        }
//        let currentAction = self.predictedAction
        self.predictedAction = "Nothing now"
//        return currentAction
    }
    
    func getPredictedAction() -> String {
        return self.predictedAction
    }
    
    // MARK: Core Motion Updates
    func startMotionUpdates(){
        // some internal inconsistency here: we need to ask the device manager for device
        
        if self.motion.isDeviceMotionAvailable{
            self.motion.deviceMotionUpdateInterval = 1.0/200
            self.motion.startDeviceMotionUpdates(to: motionOperationQueue, withHandler: self.handleMotion )
        }
    }
    
    func stopMotionUpdates(){
        // stop motion updates
        if self.motion.isDeviceMotionAvailable{
            self.motion.stopDeviceMotionUpdates()
        }
    }
    
    var handleMotionCount = 0
    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
        if let accel = motionData?.userAcceleration {
            self.ringBuffer.addNewData(xData: accel.x, yData: accel.y, zData: accel.z)
            handleMotionCount += 1
            if handleMotionCount >= 100{
                handleMotionCount = 0
                // buffer up a bit more data and then notify of occurrence
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                    // something large enough happened to warrant
                    self.largeMotionEventOccurred()
                    self.actionDone()
                    print(self.getPredictedAction())
                })
            }
        }
    }
    
    //MARK: Calibration procedure
    func largeMotionEventOccurred(){
        
        if(self.isWaitingForMotionData)
        {
            self.isWaitingForMotionData = false
            //predict a label
            let seq = toMLMultiArray(self.ringBuffer.getDataAsVector())
            guard let outputRf = try? modelRf.prediction(input: seq) else {
                fatalError("Unexpected runtime error.")
            }
            
//            guard let outputSvm = try? modelSvm.prediction(input: seq) else {
//                fatalError("Unexpected runtime error.")
//            }
//
//            guard let outputPipe = try? modelPipe.prediction(input: seq) else {
//                fatalError("Unexpected runtime error.")
//            }

            // update predicted action
            self.predictedAction = outputRf.classLabel
            print("The prediction is: \(outputRf.classLabel)")
            setDelayedWaitingToTrue(2.0)
            
            //            displayLabelResponse(outputSvm.classLabel)
            //            if(outputRf.classLabel == outputSvm.classLabel){
            //                displayLabelResponse(outputSvm.classLabel)
            //                // dont predict again for a bit
            //                setDelayedWaitingToTrue(2.0)
            //            }
            //            else{
            //                displayLabelResponse("Unknown")
            //                self.isWaitingForMotionData = true
            //            }
            
            
            
        }
    }
    
    
    func setDelayedWaitingToTrue(_ time:Double){
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: {
            self.isWaitingForMotionData = true
        })
    }

    // convert to ML Multi array
    // https://github.com/akimach/GestureAI-CoreML-iOS/blob/master/GestureAI/GestureViewController.swift
    private func toMLMultiArray(_ arr: [Double]) -> MLMultiArray {
        guard let sequence = try? MLMultiArray(shape:[150], dataType:MLMultiArrayDataType.double) else {
            fatalError("Unexpected runtime error. MLMultiArray could not be created")
        }
        let size = Int(truncating: sequence.shape[0])
        for i in 0..<size {
            sequence[i] = NSNumber(floatLiteral: arr[i])
        }
        return sequence
    }
    
//    func displayLabelResponse(_ response:String){
//        print(response)
//        switch response {
//        case "pickingup":
//            blinkLabel(upArrow)
//            break
//        case "droppingdown":
//            blinkLabel(downArrow)
//            break
//        case "unknown":
//            blinkLabel(leftArrow)
//            break
//        case "throwing":
//            blinkLabel(rightArrow)
//            break
//        default:
//            print("Unknown")
//            break
//        }
//    }
    
//    func blinkLabel(_ label:UILabel){
//        DispatchQueue.main.async {
//            self.setAsCalibrating(label)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
//                self.setAsNormal(label)
//            })
//        }
//
//    }
    
    
    
}

