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
let SERVER_URL = "http://10.8.102.50:8000" // change this for your server name!!!
// 10.8.150.132
import UIKit
import CoreMotion

class ViewController: UIViewController, URLSessionDelegate, UIPickerViewDelegate,
    UIPickerViewDataSource {
    
    // MARK: Class Properties
    var session = URLSession()
    let operationQueue = OperationQueue()
    let motionOperationQueue = OperationQueue()
    let calibrationOperationQueue = OperationQueue()
    
    var ringBuffer = RingBuffer()
    let animation = CATransition()
    let motion = CMMotionManager()
    
    var magValue = 0.1
    var isCalibrating = false
    
    var isWaitingForMotionData = false
    var knn_number = 1
    var svmKernelName = "Linear"
    var useModel = "KNN"
    
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var dsidLabel: UILabel!
    @IBOutlet weak var upArrow: UILabel!
    @IBOutlet weak var rightArrow: UILabel!
    @IBOutlet weak var downArrow: UILabel!
    @IBOutlet weak var leftArrow: UILabel!
    @IBOutlet weak var largeMotionMagnitude: UIProgressView!
    
    @IBOutlet weak var knnStepper: UIStepper!
    @IBOutlet weak var knnLabel: UILabel!
    @IBOutlet weak var svmPicker: UIPickerView!
    @IBOutlet weak var modelSelect: UISegmentedControl!
    @IBOutlet weak var knnButton: UIButton!
    @IBOutlet weak var svmButton: UIButton!
    
    // MARK: Class Properties with Observers
    enum CalibrationStage {
        case notCalibrating
        case pickingup
        case throwing // right
        case droppingdown // down
        case unknown // left
    }
    
    var calibrationStage:CalibrationStage = .notCalibrating {
        didSet{
            switch calibrationStage {
            case .pickingup:
                self.isCalibrating = true
                DispatchQueue.main.async{
                    self.setAsCalibrating(self.upArrow)
                    self.setAsNormal(self.rightArrow)
                    self.setAsNormal(self.leftArrow)
                    self.setAsNormal(self.downArrow)
                }
                break
            case .unknown:
                self.isCalibrating = true
                DispatchQueue.main.async{
                    self.setAsNormal(self.upArrow)
                    self.setAsNormal(self.rightArrow)
                    self.setAsCalibrating(self.leftArrow)
                    self.setAsNormal(self.downArrow)
                }
                break
            case .droppingdown:
                self.isCalibrating = true
                DispatchQueue.main.async{
                    self.setAsNormal(self.upArrow)
                    self.setAsNormal(self.rightArrow)
                    self.setAsNormal(self.leftArrow)
                    self.setAsCalibrating(self.downArrow)
                }
                break
                
            case .throwing:
                self.isCalibrating = true
                DispatchQueue.main.async{
                    self.setAsNormal(self.upArrow)
                    self.setAsCalibrating(self.rightArrow)
                    self.setAsNormal(self.leftArrow)
                    self.setAsNormal(self.downArrow)
                }
                break
            case .notCalibrating:
                self.isCalibrating = false
                DispatchQueue.main.async{
                    self.setAsNormal(self.upArrow)
                    self.setAsNormal(self.rightArrow)
                    self.setAsNormal(self.leftArrow)
                    self.setAsNormal(self.downArrow)
                }
                break
            }
        }
    }
    
    
    var dsid:Int = 0 {
        didSet{
            DispatchQueue.main.async{
                // update label when set
                self.dsidLabel.layer.add(self.animation, forKey: nil)
                self.dsidLabel.text = "Current DSID: \(self.dsid)"
            }
        }
    }
    // MARK: picker view delegate
    var svmKernal = ["linear", "poly", "rbf", "sigmoid"]
    
    @IBAction func modelSegementChanged(_ sender: UISegmentedControl) {
        switch self.modelSelect.selectedSegmentIndex {
        case 0:
            self.useModel = "KNN"
            self.svmPicker.isHidden = true
            self.svmButton.isHidden = true
            self.knnButton.isHidden = false
            self.knnStepper.isHidden = false
            self.knnLabel.isHidden = false
        default:
            self.useModel = "SVM"
            self.svmPicker.isHidden = false
            self.svmButton.isHidden = false
            self.knnButton.isHidden = true
            self.knnStepper.isHidden = true
            self.knnLabel.isHidden = true
            
        }
        print(self.useModel)
    }
   
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return svmKernal.count;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return svmKernal[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.svmKernelName = svmKernal[row]
        print(self.svmKernelName)
    }
    
    // vibration maginitude slider
    @IBAction func magnitudeChanged(_ sender: UISlider) {
        self.magValue = Double(sender.value)
    }
    
    // change the number of KNN neighbours
    @IBAction func knnStepperChanged(_ sender: UIStepper) {
        knn_number = Int(sender.value)
        knnLabel.text = "number of neighbours: \(knn_number)"
        
    }
    // MARK: Core Motion Updates
    func startMotionUpdates(){
        // some internal inconsistency here: we need to ask the device manager for device
        
        if self.motion.isDeviceMotionAvailable{
            self.motion.deviceMotionUpdateInterval = 1.0/200
            self.motion.startDeviceMotionUpdates(to: motionOperationQueue, withHandler: self.handleMotion )
        }
    }
    var updateTime = 0
    var handleMotionCount = 0
    
    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
        if let accel = motionData?.userAcceleration {
            handleMotionCount += 1
            self.ringBuffer.addNewData(xData: accel.x, yData: accel.y, zData: accel.z)
            let mag = fabs(accel.x)+fabs(accel.y)+fabs(accel.z)
            DispatchQueue.main.async{
                //show magnitude via indicator
                self.largeMotionMagnitude.progress = Float(mag)/0.2
            }
            
//            print("\(self.handleMotionCount)")
//            if (self.handleMotionCount >= 200){
//                self.handleMotionCount = 0
                if mag > self.magValue {
            
                     // buffer up a bit more data and then notify of occurrence
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                        self.calibrationOperationQueue.addOperation {
                            // something large enough happened to warrant
                            self.largeMotionEventOccurred()
                            
                        }
                    })
                }
            
//            }
        }
    }
    
    @objc func fire(){
        print("fire")
    }
    
    
    //MARK: Calibration procedure
    @objc func largeMotionEventOccurred(){
//        print("large motion occured")
        if(self.isCalibrating){
            //send a labeled example
            if(self.calibrationStage != .notCalibrating && self.isWaitingForMotionData)
            {
                self.isWaitingForMotionData = false
                
                // send data to the server with label
                sendFeatures(self.ringBuffer.getDataAsVector(),
                             withLabel: self.calibrationStage)
                
                self.nextCalibrationStage()
            }
        }
        else
        {
            if(self.isWaitingForMotionData)
            {
                self.isWaitingForMotionData = false
                //predict a label
                getPrediction(self.ringBuffer.getDataAsVector())
                // dont predict again for a bit
                setDelayedWaitingToTrue(2.0)
                
            }
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
            self.calibrationStage = .unknown
            setDelayedWaitingToTrue(1.0)
            break
            
        case .unknown:
            //end calibration
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
    
    func setAsCalibrating(_ label: UILabel){
        label.layer.add(animation, forKey:nil)
        label.backgroundColor = UIColor.red
    }
    
    func setAsNormal(_ label: UILabel){
        label.layer.add(animation, forKey:nil)
        label.backgroundColor = UIColor.white
    }
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.svmPicker.delegate = self
        self.svmPicker.dataSource = self
        
        self.svmPicker.isHidden = true
        self.svmButton.isHidden = true
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        setDelayedWaitingToTrue(2.0)
        dsid = 15 // set this and it will update UI
        let ds: Double = Double(dsid)
        stepper.value=ds
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        self.session = URLSession(configuration: sessionConfig,
            delegate: self,
            delegateQueue:self.operationQueue)
        
        // create reusable animation
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = kCATransitionFade
        animation.duration = 0.5
        
        
        // setup core motion handlers
        startMotionUpdates()
       
    }
    
    @IBAction func valueDidChanged(_ sender: UIStepper) {
        self.dsid = Int(sender.value)
        self.dsidLabel.text = "Current DSID: \(self.dsid)"
    }
    //MARK: Get New Dataset ID
    @IBAction func getDataSetId(_ sender: AnyObject) {
        // create a GET request for a new DSID from server
        let baseURL = "\(SERVER_URL)/GetNewDatasetId"
        
        let getUrl = URL(string: baseURL)
        let request: URLRequest = URLRequest(url: getUrl!)
        let dataTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                if(error != nil){
                    print("Response:\n%@",response!)
                }
                else{
                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    
                    // This better be an integer
                    if let dsid = jsonDictionary["dsid"]{
                        self.dsid = dsid as! Int
                    }
                }
                
        })
        
        dataTask.resume() // start the task
        
    }
    
    //MARK: Calibration
    @IBAction func startCalibration(_ sender: AnyObject) {
        self.isWaitingForMotionData = false // dont do anything yet
        nextCalibrationStage()
        
    }
    @IBAction func updateKNN(_ sender: UIButton) {
        updateKNNModel()
    }
    
    @IBAction func updateSVM(_ sender: UIButton) {
        updateSVMModel()
    }
    
    //MARK: Comm with Server, use KNN model and select KNN number to use
    func updateSVMModel(){
        let baseURL = "\(SERVER_URL)/UpdateSVMModel"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["kernel":self.svmKernelName,
                                       "dsid":self.dsid]
        
        
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        print(request)
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
                                                                  completionHandler:{(data, response, error) in
                                                                    if(error != nil){
                                                                        if let res = response{
                                                                            print("Response:\n",res)
                                                                        }
                                                                    }
                                                                    else{
//                                                                        let jsonDictionary = self.convertDataToDictionary(with: data)
                                                                        print("update SVM done!")
                                                                    }
                                                                    
        })
        
        postTask.resume() // start the task
    }
    
    
    //MARK: Comm with Server, use KNN model and select KNN number to use
    func updateKNNModel(){
        let baseURL = "\(SERVER_URL)/UpdateKNNModel"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = [
            "knn_number":self.knn_number,
            "dsid":self.dsid]
        
        
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        print(request)
        print(jsonUpload.description)
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
                                                                  completionHandler:{(data, response, error) in
                                                                    if(error != nil){
                                                                        if let res = response{
                                                                            print("Response:\n",res)
                                                                        }
                                                                    }
                                                                    else{
//                                                                        let jsonDictionary = self.convertDataToDictionary(with: data)
                                                                        print("update KNN done!")
                                                                    }
                                                                    
        })
        
        postTask.resume() // start the task
    }
    
    //MARK: Comm with Server
    func sendFeatures(_ array:[Double], withLabel label:CalibrationStage){
        let baseURL = "\(SERVER_URL)/AddDataPoint"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":array,
                                       "label":"\(label)",
                                       "dsid":self.dsid]
        
        
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        print(request)
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                if(error != nil){
                    if let res = response{
                        print("Response:\n",res)
                    }
                }
                else{
                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    
                    print(jsonDictionary["feature"]!)
                    print(jsonDictionary["label"]!)
                }

        })
        
        postTask.resume() // start the task
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
                                                                        print(labelResponse)
                                                                        self.displayLabelResponse(labelResponse as! String)

                                                                    }
                                                                    
        })
        
        postTask.resume() // start the task
    }
    
    func displayLabelResponse(_ response:String){
        switch response {
        case "['pickingup']":
            blinkLabel(upArrow)
            break
        case "['droppingdown']":
            blinkLabel(downArrow)
            break
        case "['unknown']":
            blinkLabel(leftArrow)
            break
        case "['throwing']":
            blinkLabel(rightArrow)
            break
        default:
            print("Not recognized")
            break
        }
    }
    
    func blinkLabel(_ label:UILabel){
        DispatchQueue.main.async {
            self.setAsCalibrating(label)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.setAsNormal(label)
            })
        }
        
    }
    
    @IBAction func makeModel(_ sender: AnyObject) {
        
        // create a GET request for server to update the ML model with current data
        let baseURL = "\(SERVER_URL)/UpdateModel"
        let query = "?dsid=\(self.dsid)"
        
        let getUrl = URL(string: baseURL+query)
        let request: URLRequest = URLRequest(url: getUrl!)
        let dataTask : URLSessionDataTask = self.session.dataTask(with: request,
              completionHandler:{(data, response, error) in
                // handle error!
                if (error != nil) {
                    if let res = response{
                        print("Response:\n",res)
                    }
                }
                else{
                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    
                    if let resubAcc = jsonDictionary["resubAccuracy"]{
                        print("Resubstitution Accuracy is", resubAcc)
                    }
                }
                                                                    
        })
        
        dataTask.resume() // start the task
        
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





