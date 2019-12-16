//
//  ViewController.swift
//  HTTPSwiftExample
//
//  Created by Eric Larson on 3/30/15.
//  Copyright (c) 2015 Eric Larson. All rights reserved.
//

// This exampe is meant to be run with the python example:
//              tornado_example.py
//              from the course GitHub repository: tornado_bare, branch sklearn_example


// if you do not know your local sharing server name try:
//    ifconfig |grep inet
// to see what your public facing IP address is, the ip address can be used here
//let SERVER_URL = "http://erics-macbook-pro.local:8000" // change this for your server name!!!


import UIKit
import CoreMotion

class HttpPredictController: UIViewController, URLSessionDelegate, ActionHttpDelegate {
//    init() {
//        URLSession(configuration: .default)
//    }
    
    let SERVER_URL = "http://10.8.127.58:8000" // change this for your server name!!!
    // MARK: Class Properties
    static let sharedInstance = HttpPredictController()


    var session = URLSession()
    let operationQueue = OperationQueue()
    let motionOperationQueue = OperationQueue()
    let calibrationOperationQueue = OperationQueue()
    var predictedAction = "Nothing now!"
    // create buffer to store the data to be uploaded
    var ringBuffer = RingBuffer()
    let animation = CATransition()
    let motion = CMMotionManager()
    var longPressGesture = UILongPressGestureRecognizer()
    
    var magValue = 0.1
    var isCalibrating = false
    
    var isWaitingForMotionData = true
    var knn_number = 1
    var svmKernelName = "Linear"
    var useModel = "KNN"
    var isPredicting: Bool = false
    
//    init(session: URLSession) {
//        let sessionConfig = URLSessionConfiguration.ephemeral
//        sessionConfig.timeoutIntervalForRequest = 5.0
//        sessionConfig.timeoutIntervalForResource = 8.0
//        sessionConfig.httpMaximumConnectionsPerHost = 1
//
//        self.session = URLSession(configuration: sessionConfig,
//                                  delegate: self,
//                                  delegateQueue:self.operationQueue)
//    }
    
//    @IBOutlet weak var stepper: UIStepper!
//    @IBOutlet weak var dsidLabel: UILabel!
//    @IBOutlet weak var upArrow: UILabel!
//    @IBOutlet weak var rightArrow: UILabel!
//    @IBOutlet weak var downArrow: UILabel!
//    @IBOutlet weak var leftArrow: UILabel!
//    @IBOutlet weak var largeMotionMagnitude: UIProgressView!
//    @IBOutlet weak var knnStepper: UIStepper!
//    @IBOutlet weak var knnLabel: UILabel!
//    @IBOutlet weak var svmPicker: UIPickerView!
//    @IBOutlet weak var modelSelect: UISegmentedControl!
//    @IBOutlet weak var knnButton: UIButton!
//    @IBOutlet weak var svmButton: UIButton!
//    @IBOutlet weak var recordMotionButton: UIButton!
//    @IBOutlet weak var recordbuttonImage: UIImageView!
    
    // MARK: Class Properties with Observers
    enum CalibrationStage {
        case notCalibrating
        case pickingup
        case throwing // right
        case droppingdown // down
    }
    
    var calibrationStage:CalibrationStage = .notCalibrating {
        didSet{
            switch calibrationStage {
            case .pickingup:
                self.isCalibrating = true
                break
            case .droppingdown:
                self.isCalibrating = true
                break
                
            case .throwing:
                self.isCalibrating = true
                break
            case .notCalibrating:
                self.isCalibrating = false
                break
            }
        }
    }
    
    
    var dsid:Int = 9 {
        didSet{
        }
    }
    
    
    func urlInitialization(){
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        self.session = URLSession(configuration: sessionConfig,
                                  delegate: self,
                                  delegateQueue:self.operationQueue)
    }
    
    func prepareUrl() {
        self.urlInitialization()
    }
    
//    // MARK: button hold-down and touch-up event
//    @objc func buttonDown(_ sender: UIButton) {
//        print("button down")
//        self.handleMotionCount = 0
//        self.isPredicting = true
//        startMotionUpdates()
//    }
//
//    @objc func buttonUp(_ sender: UIButton) {
//        print("button up")
//        self.stopMotionUpdates()
//        // In case the player doesn't hold the button for enouogh time, it will still predict something
//        if(self.isPredicting == true){
//            self.largeMotionEventOccurred()
//        }
//    }
    
    // MARK: picker view delegate
    var svmKernal = ["linear", "poly", "rbf", "sigmoid"]
    
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
    
    
    var updateTime = 0
    
    var handleMotionCount = 0
    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
        if let accel = motionData?.userAcceleration {
            self.ringBuffer.addNewData(xData: accel.x, yData: accel.y, zData: accel.z)
            print(handleMotionCount)
            handleMotionCount += 1
            if handleMotionCount >= 100{
                handleMotionCount = 0
                // buffer up a bit more data and then notify of occurrence
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                    // something large enough happened to warrant
                    self.largeMotionEventOccurred()
                    print("hello")
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
            getPrediction(self.ringBuffer.getDataAsVector())
            print("largemotion occurd")
            // dont predict again for a bit
            setDelayedWaitingToTrue(2.0)
        }
        
    }
    
    func nextCalibrationStage(){
        switch self.calibrationStage {
        case .notCalibrating:
            //start with up arrow
            self.calibrationStage = .pickingup
            setDelayedWaitingToTrue(1.0)
            break
        case .pickingup:
            //go to right arrow
            self.calibrationStage = .throwing
            setDelayedWaitingToTrue(1.0)
            break
        case .throwing:
            //go to down arrow
            self.calibrationStage = .droppingdown
            setDelayedWaitingToTrue(1.0)
            break
        case .droppingdown:
            //go to left arrow
            self.calibrationStage = .notCalibrating
            setDelayedWaitingToTrue(1.0)
            break
        }
    }
    
    func setDelayedWaitingToTrue(_ time:Double){
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: {
            self.isWaitingForMotionData = true
        })
    }
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        setDelayedWaitingToTrue(2.0)
        
        // set this and it will update UI
        dsid = 9

        
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        self.session = URLSession(configuration: sessionConfig,
                                  delegate: self,
                                  delegateQueue:self.operationQueue)
        
        // create reusable animation
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.fade
        animation.duration = 0.5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.all)
    }
    
    func getPrediction(_ array:[Double]){
        let baseURL = "\(SERVER_URL)/PredictOne"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":array, "dsid":self.dsid]
        print("dsid: \(self.dsid)")
        
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        print(request)
        print(jsonUpload)
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
                                                                  completionHandler:{(data, response, error) in
                                                                    if(error != nil){
                                                                        if let res = response{
                                                                            print("Response:\n",res)
                                                                        }
                                                                    }
                                                                    else{
                                                                        let jsonDictionary = self.convertDataToDictionary(with: data)
                                                                        
                                                                        let labelResponse = jsonDictionary["prediction"]!
                                                                        self.predictedAction = labelResponse as! String
                                                                        
                                                                    }
                                                                    
        })
        
        postTask.resume() // start the task
    }
    
    //MARK: JSON Conversion Functions
    func convertDictionaryToData(with jsonUpload:NSDictionary) -> Data?{
        do { // try to make JSON and deal with errors using do/catch block
            let requestBody = try JSONSerialization.data(withJSONObject: jsonUpload, options:JSONSerialization.WritingOptions.prettyPrinted)
            return requestBody
        } catch {
            print("json error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func convertDataToDictionary(with data:Data?)->NSDictionary{
        do { // try to parse JSON and deal with errors using do/catch block
            let jsonDictionary: NSDictionary =
                try JSONSerialization.jsonObject(with: data!,
                                                 options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            return jsonDictionary
            
        } catch {
            print("json error: \(error.localizedDescription)")
            return NSDictionary() // just return empty
        }
    }
    
}








////
////  HttpPredictController.swift
////  final_project
////
////  Created by Zhenxuan Ouyang on 12/14/19.
////  Copyright © 2019 5324. All rights reserved.
////
//
//import Foundation
//import UIKit
//import CoreMotion
//import CoreML
//
//
//class HttpPredictController: ActionHttpDelegate, URLSessionDelegate{
//    // make it a shared instance, only one instance can exist at an application
//    static let sharedInstance = HttpPredictController()
//    // rewrite the init function to make it invisible to other class
//    private init(){
//        self.initializer()
//    }
//
//    let SERVER_URL = "http://192.168.1.81:8000" // change this for your server name!!!
//
//    var ringBuffer = RingBuffer()
//    var session = URLSession()
//    let animation = CATransition()
//    var dsid = 9
//    let motion = CMMotionManager()
//
//    let motionOperationQueue = OperationQueue()
//    let operationQueue = OperationQueue()
//
//    var magValue = 0.1
//    var isCalibrating = false
//
//    var isWaitingForMotionData = true
//
////    var modelRf = SVMAccel9()
//
//    var predictedAction = "Nothing now!"
//    var isPredicting = false
//
//    enum CalibrationStage {
//        case notCalibrating
//        case pickingup
//        case throwing // right
//        case droppingdown // down
//    }
//
//    var calibrationStage:CalibrationStage = .notCalibrating {
//        didSet{
//            switch calibrationStage {
//            case .pickingup:
//                self.isCalibrating = true
////                DispatchQueue.main.async{
////                    self.setAsCalibrating(self.upArrow)
////                    self.setAsNormal(self.rightArrow)
////                    self.setAsNormal(self.leftArrow)
////                    self.setAsNormal(self.downArrow)
////                }
//                break
//            case .droppingdown:
//                self.isCalibrating = true
////                DispatchQueue.main.async{
////                    self.setAsNormal(self.upArrow)
////                    self.setAsNormal(self.rightArrow)
////                    self.setAsNormal(self.leftArrow)
////                    self.setAsCalibrating(self.downArrow)
////                }
//                break
//
//            case .throwing:
//                self.isCalibrating = true
////                DispatchQueue.main.async{
////                    self.setAsNormal(self.upArrow)
////                    self.setAsCalibrating(self.rightArrow)
////                    self.setAsNormal(self.leftArrow)
////                    self.setAsNormal(self.downArrow)
////                }
//                break
//            case .notCalibrating:
//                self.isCalibrating = false
////                DispatchQueue.main.async{
////                    self.setAsNormal(self.upArrow)
////                    self.setAsNormal(self.rightArrow)
////                    self.setAsNormal(self.leftArrow)
////                    self.setAsNormal(self.downArrow)
////                }
//                break
//            }
//        }
//    }
//
//    func initializer(){
//        let sessionConfig = URLSessionConfiguration.ephemeral
//
//        sessionConfig.timeoutIntervalForRequest = 5.0
//        sessionConfig.timeoutIntervalForResource = 8.0
//        sessionConfig.httpMaximumConnectionsPerHost = 1
//
////        self.session = URLSession(configuration: sessionConfig,
////                                  delegate: self,
////                                  delegateQueue:self.operationQueue)
//    }
//
//    func actionBegin() {
//        print("action begin")
//        self.isPredicting = true
//        startMotionUpdates()
//    }
//
//    func actionDone() {
//        print("action done")
//        stopMotionUpdates()
//        self.isPredicting = false
//    }
//
//    func updatePredictedAction() {
//        //        print("get predicted action")
//        if self.isPredicting == true{
//            self.predictedAction = "It's still predicting right now, the result isn't available"
//        }
//        //        let currentAction = self.predictedAction
//        self.predictedAction = "Nothing now"
//        //        return currentAction
//    }
//
//    func getPredictedAction() -> String {
//        return self.predictedAction
//    }
//
//    func startMotionUpdates(){
//        // some internal inconsistency here: we need to ask the device manager for device
//
//        if self.motion.isDeviceMotionAvailable{
//            self.motion.deviceMotionUpdateInterval = 1.0/200
//            self.motion.startDeviceMotionUpdates(to: motionOperationQueue, withHandler: self.handleMotion )
//        }
//    }
//
//    func stopMotionUpdates(){
//        // stop motion updates
//        if self.motion.isDeviceMotionAvailable{
//            self.motion.stopDeviceMotionUpdates()
//        }
//    }
//    var handleMotionCount = 0
//    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
//        if let accel = motionData?.userAcceleration {
//            self.ringBuffer.addNewData(xData: accel.x, yData: accel.y, zData: accel.z)
//            print(handleMotionCount)
//            handleMotionCount += 1
//            if handleMotionCount >= 100{
//                handleMotionCount = 0
//                // buffer up a bit more data and then notify of occurrence
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
//                    // something large enough happened to warrant
//                    self.largeMotionEventOccurred()
//                    self.actionDone()
//                    print(self.getPredictedAction())
//                })
//            }
//        }
//    }
//
//    //MARK: Calibration procedure
//    @objc func largeMotionEventOccurred(){
//
//        if(self.isWaitingForMotionData)
//        {
//            self.isWaitingForMotionData = false
//            //predict a label
//            getPrediction(self.ringBuffer.getDataAsVector())
//            // dont predict again for a bit
//            setDelayedWaitingToTrue(2.0)
//        }
//
//    }
//
//    //MARK: Comm with Server
//    func sendFeatures(_ array:[Double], withLabel label:CalibrationStage){
//        let baseURL = "\(SERVER_URL)/AddDataPoint"
//        let postUrl = URL(string: "\(baseURL)")
//
//        // create a custom HTTP POST request
//        var request = URLRequest(url: postUrl!)
//
//        // data to send in body of post request (send arguments as json)
//        let jsonUpload:NSDictionary = ["feature":array,
//                                       "label":"\(label)",
//            "dsid":self.dsid]
//
//
//
//        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
//
//        request.httpMethod = "POST"
//        request.httpBody = requestBody
//        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
//                                                                  completionHandler:{(data, response, error) in
//                                                                    if(error != nil){
//                                                                        if let res = response{
//                                                                            print("Response:\n",res)
//                                                                        }
//                                                                    }
//                                                                    else{
//                                                                        let jsonDictionary = self.convertDataToDictionary(with: data)
//
//                                                                        print(jsonDictionary["feature"]!)
//                                                                        print(jsonDictionary["label"]!)
//                                                                    }
//
//        })
//
//        postTask.resume() // start the task
//    }
//
//    func getPrediction(_ array:[Double]){
//        let baseURL = "\(SERVER_URL)/PredictOne"
//        let postUrl = URL(string: "\(baseURL)")
//
//        // create a custom HTTP POST request
//        var request = URLRequest(url: postUrl!)
//
//        // data to send in body of post request (send arguments as json)
//        let jsonUpload:NSDictionary = ["feature":array, "dsid":self.dsid]
//        print("dsid: \(self.dsid)")
//
//        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
//
//        request.httpMethod = "POST"
//        request.httpBody = requestBody
//        print(request)
//        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
//                                                                  completionHandler:{(data, response, error) in
//                                                                    if(error != nil){
//                                                                        if let res = response{
//                                                                            print("Response:\n",res)
//                                                                        }
//                                                                    }
//                                                                    else{
//                                                                        let jsonDictionary = self.convertDataToDictionary(with: data)
//
//                                                                        let labelResponse = jsonDictionary["prediction"]!
//                                                                        print(labelResponse)
////                                                                        self.displayLabelResponse(labelResponse as! String)
//
//                                                                    }
//
//        })
//
//        postTask.resume() // start the task
//    }
//
//    //MARK: JSON Conversion Functions
//    func convertDictionaryToData(with jsonUpload:NSDictionary) -> Data?{
//        do { // try to make JSON and deal with errors using do/catch block
//            let requestBody = try JSONSerialization.data(withJSONObject: jsonUpload, options:JSONSerialization.WritingOptions.prettyPrinted)
//            return requestBody
//        } catch {
//            print("json error: \(error.localizedDescription)")
//            return nil
//        }
//    }
//
//    func convertDataToDictionary(with data:Data?)->NSDictionary{
//        do { // try to parse JSON and deal with errors using do/catch block
//            let jsonDictionary: NSDictionary =
//                try JSONSerialization.jsonObject(with: data!,
//                                                 options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
//
//            return jsonDictionary
//
//        } catch {
//            print("json error: \(error.localizedDescription)")
//            return NSDictionary() // just return empty
//        }
//    }
//
//    func setDelayedWaitingToTrue(_ time:Double){
//        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: {
//            self.isWaitingForMotionData = true
//        })
//    }
//
//}
