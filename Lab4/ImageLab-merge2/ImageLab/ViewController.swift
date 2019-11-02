//
//  ViewController.swift
//  ImageLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import AVFoundation
import Charts

// Module B part
class ViewController: UIViewController   {

    @IBOutlet weak var chtChart: LineChartView!
    @IBOutlet weak var measureButton: UIButton!
    @IBOutlet weak var secondLabel: UILabel!
    
    //MARK: Class Properties
    // initial variables for heart rate detection
    var filters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    var detector:CIDetector! = nil
    
    var bgrData: [Double] = [1.0]
    var tempdata: Double = 1.0
    var tempArray: Array<Double> = []
    
    var isFinger:Bool = false
    var heartRateTimer: Timer?
    var seconds:Float = 0
    
    var timing:Bool = false
    var measure:Bool = false
    var redness = [Float]()
    
    var graphTimer: Timer?
    
    let pinchFilterIndex = 2
    let bridge = OpenCVBridge()
    
    //MARK: Outlets in view
    @IBOutlet weak var flashSlider: UISlider!
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //function to set chart to virtualize heart rate
        self.setCharts()
        
        self.view.backgroundColor = nil
        // set up video manager
        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
        
        // create dictionary for face detection
        // HINT: you need to manipulate these proerties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyLow]
        
        // setup a face detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: self.videoManager.getCIContext(), // perform on the GPU is possible
                                  options: optsDetector)
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        self.bridge.setTransforms(self.videoManager.transform)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
        
        self.bridge.processType = 1
    }
    
    // when view will appear, run the graph
    override func viewWillAppear(_ animated: Bool) {
        runGraphTimer()
    }
    
    // function to run the timer to run graph
    func runGraphTimer(){
        self.graphTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateCharts), userInfo: nil, repeats: true)
    }
    
    // function to stop the graph timer when complete
    func stopGraphTimer(){
        self.graphTimer?.invalidate()
        self.graphTimer = nil
    }
    
    // function to run timer to calculate time that finger puts on the screen
    func runHeartRateTimer() {
        self.redness = []
        self.heartRateTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self,   selector: (#selector(ViewController.updateHeartRateTimer)), userInfo: nil, repeats: true)
    }
    
    // function to stop the heart rate timer
    func killHeartRateTimer() {
        heartRateTimer!.invalidate()
    }
    
    // function that heart rate timer will use to count time every 0.1 second
    @objc func updateHeartRateTimer() {
        self.seconds += 0.1
    }
    
    // algorithm to calculate heart rate
    func heartRateCal(){
        var count:Float = 0.0
        let size = self.redness.count
        let bufferSize=10
        for i in 1...(size-1-bufferSize) {
            let mid = i+bufferSize/2
            var localMin = self.redness[i]
            var minInd = i
            for j in i+1...(i+bufferSize){
                if self.redness[j]>localMin {
                    localMin=self.redness[j]
                    minInd=j
                }
            }
            if mid == minInd {
                count+=1
            }
        }
        
        // We do not collect data from the first two second for the sake of accuracy
        let bpm = count/(self.seconds-2)*60.0
        
        // once get the final result, shown on the screen
        self.secondLabel.text = "Your heart rate is " + String(format: "%.1f", bpm)
        self.measureButton.isHidden = false
        self.measure = false
        self.timing = false
        self.redness = []
    }
    
    // button function to start measure heart rate
    @IBAction func startMeasure(_ sender: Any) {
        self.measureButton.isHidden = true
        self.seconds = 0
        self.measure = true
    }
    
    
    func makeList(_ n: Int) -> [Double] {
        return (0..<n).map { _ in .random(in: 1...80) }
    }
    
    // function to set up the heart rate chart
    @objc func setCharts(){
        chtChart.chartDescription?.text = "My awesome chart"
        chtChart.backgroundColor = #colorLiteral(red: 1, green: 0.7861487269, blue: 0.8041584492, alpha: 1)
        
    }
    
    // function to update chart based on the data sending back from openCV
    @objc func updateCharts(){
        var lineChartEntry = [ChartDataEntry]()
        print("Timer running")
        
        if(self.redness.count != 0){
            for i in 0..<self.redness.count{
                let value = ChartDataEntry(x: Double(i), y: Double(self.redness[i]))
                lineChartEntry.append(value)
            }
        }else{
            for i in 0..<10{
                let value = ChartDataEntry(x: Double(i), y: Double(0.0))
                lineChartEntry.append(value)
            }
        }
        let line1 = LineChartDataSet(entries: lineChartEntry, label: "Number")
        line1.colors = [NSUIColor.blue]
        line1.circleColors = [UIColor.green]
        
        let data = LineChartData()
        data.addDataSet(line1)
        
        chtChart.data = data
        chtChart.data?.notifyDataChanged()
        chtChart.notifyDataSetChanged()
        chtChart.setVisibleXRangeMaximum(100)
        chtChart.moveViewToX(Double(self.redness.count))
    }
    
    //MARK: Process image output
    // function processImage to process the camera result
    func processImage(inputImage:CIImage) -> CIImage{
        
        var retImage = inputImage
        
        // use this code if you are using OpenCV and want to overwrite the displayed image via OpenCv
        // this is a BLOCKING CALL
        self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
        self.bridge.setTransforms(self.videoManager.transform)
        
        // call processfinger function to return redness results
        let pF=self.bridge.processFinger()
        
        // if there is a finger, start measure
        if(pF>0){
            // turn on the flash
            self.videoManager.turnOnFlashwithLevel(0.1)
            // if time is greater than 15, stop timing
            DispatchQueue.main.async {
                if(self.seconds >= 15 && self.measure){
                    self.killHeartRateTimer()
                    self.heartRateCal()
                }
                // if time is greater than 2 seconds, start collecting data
                else if(self.seconds>2 && self.measure){
                    self.redness.append(pF)
                }
                // if timing button is pressed, call timer function to start timing
                if(!self.timing && self.measure){
                    if(!self.isFinger){
                        self.isFinger = true}
                    self.timing = true
                    self.runHeartRateTimer()
                }
                // show the time on the screen
                if(self.measure){
                    self.secondLabel.text = String(self.seconds);
                }
            }
        // if there is no finger on the screen, turn off the flash and clear the data
        }else{
            self.videoManager.turnOffFlash()
            DispatchQueue.main.async {
                if(self.isFinger && self.measure){
                    self.killHeartRateTimer()
                    self.seconds = 0
                    self.timing = false
                    self.isFinger = false
                    self.redness = []
                }
            }
        }
        retImage = self.bridge.getImage()
        
        //HINT: you can also send in the bounds of the face to ONLY process the face in OpenCV
        // or any bounds to only process a certain bounding region in OpenCV
        
        return retImage
    }
    
    // function to stop video manager and timer when leave the module
    override func viewWillDisappear(_ animated: Bool) {
        self.videoManager.stop()
        if(self.timing){
            killHeartRateTimer()
        }
        stopGraphTimer()
    }

   
}

