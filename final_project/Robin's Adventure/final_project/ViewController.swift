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
let SERVER_URL = "http://192.168.1.81:8000" // change this for your server name!!!
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
    
    // create buffer to store the data to be uploaded
    var ringBuffer = RingBuffer()
    let animation = CATransition()
    let motion = CMMotionManager()
    var longPressGesture = UILongPressGestureRecognizer()
    
    var magValue = 0.1
    var isCalibrating = false
    
    var isWaitingForMotionData = false
    var knn_number = 1
    var svmKernelName = "Linear"
    var useModel = "KNN"
    var isPredicting: Bool = false
    
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
    @IBOutlet weak var recordMotionButton: UIButton!
    
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
                DispatchQueue.main.async{
                    self.setAsCalibrating(self.upArrow)
                    self.setAsNormal(self.rightArrow)
                    self.setAsNormal(self.leftArrow)
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
    
    // MARK: button hold-down and touch-up event
    @objc func buttonDown(_ sender: UIButton) {
        self.handleMotionCount = 0
        self.isPredicting = true
        startMotionUpdates()
    }
    
    @objc func buttonUp(_ sender: UIButton) {
        self.stopMotionUpdates()
        // In case the player doesn't hold the button for enouogh time, it will still predict something
        if(self.isPredicting == true){
            self.largeMotionEventOccurred()
        }
    }
    
    // MARK: picker view delegate
    var svmKernal = ["linear", "poly", "rbf", "sigmoid"]
    
    // when changing the model with the segemented bar, hide some unrelated buttons
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
    
    // vibration maginitude slider
    @IBAction func magnitudeChanged(_ sender: UISlider) {
        self.magValue = Double(sender.value)
    }
    
    // change the number of KNN neighbours
    @IBAction func knnStepperChanged(_ sender: UIStepper) {
        knn_number = Int(sender.value)
        knnLabel.text = "number of neighbours: \(knn_number)"
        
    }
   
    // picker view initialization
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
    

    // MARK: Core Motion Updates
    func startMotionUpdates(){
        // some internal inconsistency here: we need to ask the device manager for device
        
        if self.motion.isDeviceMotionAvailable{
            self.motion.deviceMotionUpdateInterval = 1.0/200.0
            self.motion.startDeviceMotionUpdates(to: motionOperationQueue, withHandler: self.handleMotion )
        }
    }
    
    // MARK: Stop Core Motion Updates
    func stopMotionUpdates(){
        print("stop motion updates")
        self.motion.stopDeviceMotionUpdates()
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
            
            // when count reaches 100, can be possible to enter predict mode
            if(self.isCalibrating == true){
                if(mag > self.magValue){
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                        self.calibrationOperationQueue.addOperation {
                            // something large enough happened to warrant
                            self.largeMotionEventOccurred()
                            // turn the predicting mode to false
                            self.isPredicting = false
                        }
                    })
                }
            }else if(self.isPredicting == true){
                // when it's predicting, only upload the sensor data when handleMotionCount reaches 100
                print(handleMotionCount)
                if(self.handleMotionCount >= 100){
                    self.handleMotionCount = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                        self.calibrationOperationQueue.addOperation {
                            // something large enough happened to warrant
                            self.largeMotionEventOccurred()
                            // turn the predicting mode to false
                            self.isPredicting = false
                        }
                    })
                }else{
                    print("Not in predicting node~")
                }
                
            }
        }
    }
    
    //MARK: Calibration procedure
    @objc func largeMotionEventOccurred(){
        if(self.isCalibrating){
            //send a labeled example
            if(self.calibrationStage != .notCalibrating && self.isWaitingForMotionData)
            {
                self.isWaitingForMotionData = false
                
                // set delay to 1 second to collect enough data
                let seconds = 1.0
                // send data to the server with label
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                    // Put your code which should be executed with a delay here
                    self.sendFeatures(self.ringBuffer.getDataAsVector(),
                                      withLabel: self.calibrationStage)
                    self.nextCalibrationStage()
                }
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
    
    @objc func longPress(_ sender: UILongPressGestureRecognizer){
        let alertController = UIAlertController(title: "Long Press", message:
            "Long Press Gesture Detected", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default,handler: nil))
        present(alertController, animated: true, completion: nil)
        print("hello")
    
    }
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.leftArrow.isHidden = true
        self.svmPicker.delegate = self
        self.svmPicker.dataSource = self
        self.svmPicker.isHidden = true
        self.svmButton.isHidden = true

        // add hold-down and touch-up event to the button
        self.recordMotionButton.addTarget(self, action: #selector(buttonDown), for: .touchDown)
        self.recordMotionButton.addTarget(self, action: #selector(buttonUp), for: [.touchUpInside, .touchUpOutside])
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        setDelayedWaitingToTrue(2.0)
        
        // set this and it will update UI
        dsid = 8
        // update the stepper value
        let ds: Double = Double(dsid)
        stepper.value=ds
        
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
        self.startMotionUpdates()
        nextCalibrationStage()
        
    }
    @IBAction func updateKNN(_ sender: UIButton) {
        updateKNNModel()
    }
    
    @IBAction func updateSVM(_ sender: UIButton) {
        updateSVMModel()
    }
    
    //MARK: Comm with Server, use SVM model and select SVM kernel to use with POST method
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
                                                                        print("update SVM done!")
                                                                    }
                                                                    
        })
        
        postTask.resume() // start the task
    }
    
    
    //MARK: Comm with Server, use KNN model and select KNN number to use with POST method
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





