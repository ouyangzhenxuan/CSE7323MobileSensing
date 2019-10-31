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

class ViewController: UIViewController   {

    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    
    @IBOutlet weak var chtChart: LineChartView!
    
    @IBOutlet weak var measureButton: UIButton!
    @IBOutlet weak var secondLabel: UILabel!
    
    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    var detector:CIDetector! = nil
    
    var bgrData: [Double] = [1.0]
    var tempdata: Double = 1.0
    var tempArray: Array<Double> = []
    
    var isFinger:Bool = false
    var timer: Timer?
    var seconds:Float = 0
    
    var measure:Bool = false
    var redness = [Float]()
    
    let pinchFilterIndex = 2
    let bridge = OpenCVBridge()
    
    //MARK: Outlets in view
    @IBOutlet weak var flashSlider: UISlider!
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setCharts()
        
        self.view.backgroundColor = nil
        self.setupFilters()
        
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
        
//        let timer = Timer(timeInterval: 1.0, target: self, selector: #selector(fire), userInfo: nil, repeats: true)
        let timer1 = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateCharts), userInfo: nil, repeats: true)
    
    }
    
    func runTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self,   selector: (#selector(ViewController.updateTimer)), userInfo: nil, repeats: true)
    }
    
    func killTimer() {
        timer!.invalidate()
    }
    
    @objc func updateTimer() {
        self.seconds += 0.1
    }
    
    func heartRateCal(){
        //        var peakVal = [Float]()
        //        var incrementElement = self.redness[0]
        var count:Float = 0.0
        let size = self.redness.count
        let bufferSize=10
        for i in 1...(size-1-bufferSize) {
            let mid = i+bufferSize/2
            var localMax = self.redness[i]
            var maxInd = i
            for j in i+1...(i+bufferSize){
                if self.redness[j]>localMax {
                    localMax=self.redness[j]
                    maxInd=j
                }
            }
            if mid == maxInd {
                count+=1
            }
        }
        let bpm = count/(self.seconds-2)*60.0
        
        self.secondLabel.text = "Your heart rate is " + String(format: "%.1f", bpm)
        self.measureButton.isHidden = false
        self.measure = false
    }
    
    @IBAction func startMeasure(_ sender: Any) {
        self.measureButton.isHidden = true
        self.seconds = 0
        self.measure = true
    }
    
    
    func makeList(_ n: Int) -> [Double] {
        return (0..<n).map { _ in .random(in: 1...80) }
    }
    
    @objc func setCharts(){
        chtChart.chartDescription?.text = "My awesome chart"
        chtChart.backgroundColor = #colorLiteral(red: 1, green: 0.7861487269, blue: 0.8041584492, alpha: 1)
    }
    
    @objc func updateCharts(){
        if(self.redness.count != 0){
            
            var lineChartEntry = [ChartDataEntry]()
            print("Timer running")
            
            for i in 0..<self.redness.count{
                let value = ChartDataEntry(x: Double(i), y: Double(self.redness[i]))
                lineChartEntry.append(value)
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
    }
    
    //MARK: Process image output
    func processImage(inputImage:CIImage) -> CIImage{
        
        var retImage = inputImage
        
        // use this code if you are using OpenCV and want to overwrite the displayed image via OpenCv
        // this is a BLOCKING CALL
        self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
        self.bridge.setTransforms(self.videoManager.transform)
        
        let pF=self.bridge.processFinger()
        
        if(pF>0){
            self.videoManager.turnOnFlashwithLevel(0.1)
            DispatchQueue.main.async {
                if(self.seconds >= 15 && self.measure){
                    self.killTimer()
                    self.heartRateCal()
                }
                else if(self.seconds>2 && self.measure){
                    self.redness.append(pF)
                }
                if(!self.isFinger && self.measure){
                    self.isFinger = true
                    self.runTimer()
                }
//                self.flashButton.isEnabled=false
                self.cameraButton.isEnabled=false
                if(self.measure){
                    self.secondLabel.text = String(self.seconds);
                }
            }
        }else{
            self.videoManager.turnOffFlash()
            DispatchQueue.main.async {
                if(self.isFinger && self.measure){
                    self.killTimer()
                    self.seconds = 0
                    self.isFinger = false
                    self.redness = []
                }
//                self.flashButton.isEnabled=true
                self.cameraButton.isEnabled=true
            }
        }
        retImage = self.bridge.getImage()
        
        //HINT: you can also send in the bounds of the face to ONLY process the face in OpenCV
        // or any bounds to only process a certain bounding region in OpenCV
        
        return retImage
    }
    
    //MARK: Setup filtering
    func setupFilters(){
        filters = []
        
        let filterPinch = CIFilter(name:"CIBumpDistortion")!
        filterPinch.setValue(-0.5, forKey: "inputScale")
        filterPinch.setValue(75, forKey: "inputRadius")
        filters.append(filterPinch)
        
    }
    
    //MARK: Apply filters and apply feature detectors
    func applyFiltersToFaces(inputImage:CIImage,features:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        var filterCenter = CGPoint()
        
        for f in features {
            //set where to apply filter
            filterCenter.x = f.bounds.midX
            filterCenter.y = f.bounds.midY
            
            //do for each filter (assumes all filters have property, "inputCenter")
            for filt in filters{
                filt.setValue(retImage, forKey: kCIInputImageKey)
                filt.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
                // could also manipualte the radius of the filter based on face size!
                retImage = filt.outputImage!
            }
        }
        return retImage
    }
    
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
    
    
    //MARK: Convenience Methods for UI Flash and Camera Toggle
    @IBAction func flash(sender: AnyObject) {
        if(self.videoManager.toggleFlash()){
            self.flashSlider.value = 1.0
        }
        else{
            self.flashSlider.value = 0.0
        }
//        self.videoManager.toggleFlash()
    }
    
    @IBAction func switchCamera(sender: AnyObject) {
        self.videoManager.toggleCameraPosition()
    }
    
    @IBAction func setFlashLevel(sender: UISlider) {
        if(sender.value>0.0){
            self.videoManager.turnOnFlashwithLevel(sender.value)
        }
        else if(sender.value==0.0){
            self.videoManager.turnOffFlash()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.videoManager.stop()
    }

   
}

