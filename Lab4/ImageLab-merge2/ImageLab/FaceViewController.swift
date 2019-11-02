//
//  ViewController.swift
//  ImageLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import AVFoundation

class FaceViewController: UIViewController   {
    //MARK: Class Properties
    @IBOutlet weak var cameraButton: UIButton!
    
    var videoManager:VideoAnalgesic! = nil
    let pinchFilterIndex = 2
    let bridge = OpenCVBridge()
    var detector:CIDetector! = nil
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        
        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
        
        // create dictionary for face detection
    let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyHigh, CIDetectorTracking:true,CIDetectorSmile:true,CIDetectorEyeBlink:true] as [String : Any]
        
        // setup a face detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                   context: self.videoManager.getCIContext(), // perform on the GPU is possible
            options: (optsDetector as [String : AnyObject]))
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
        self.bridge.setTransforms(self.videoManager.transform)
        self.bridge.processType=1
    }
    
    //MARK: Apply filters and apply feature detectors
    func applyFiltersToFaces(inputImage:CIImage,features:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        
        // get feature postion
        
        var filterCenter = CGPoint()
        var leftEyeCenter = CGPoint()
        var rightEyeCenter = CGPoint()
        var mouthCenter = CGPoint()
        
        self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
        
        //prepare texts to be displayed using cv::putText
        self.bridge.setTransforms(self.videoManager.transform)
        for f in features {
            //set where to apply filter
            filterCenter.x = f.bounds.midX
            filterCenter.y = f.bounds.midY
            var stringList = [String]()
            var displayString = ""
            if(f.hasSmile){
                displayString+="Smiling! "
                stringList.append("Smiling! ")
            }else{
                displayString+="Not Smiling! "
                stringList.append("Not Smiling! ")
            }
            
            if(f.leftEyeClosed==true||f.rightEyeClosed==true){
                displayString+="Blinking! "
                stringList.append("Blinking! ")
            }else{
                displayString+="Not Blinking! "
                stringList.append("Not Blinking! ")
            }
            
            // switch the way it displays
            if UIDevice.current.orientation.isLandscape {
                var i = 0
                for str in stringList{
                    self.bridge.display(str, withCenter: CGPoint.init(x: filterCenter.y + CGFloat(i*40),y: filterCenter.x + CGFloat(i*5)))
                    i += 1
                }
            } else {
                var i = 0
                for str in stringList{
                    self.bridge.display(str, withCenter: CGPoint.init(x: filterCenter.x + CGFloat(i*40), y: filterCenter.y + CGFloat(i*5)))
                    i += 1
                }
            }
        }
        
        if let img = self.bridge.getImage() {
            retImage = img
        }
        
        // apply filtes to each feature
        
        for f in features {
            filterCenter.x = f.bounds.midX
            filterCenter.y = f.bounds.midY
            leftEyeCenter = f.leftEyePosition
            rightEyeCenter = f.rightEyePosition
            mouthCenter = f.mouthPosition
            //do for each filter (assumes all filters have property, "inputCenter")
            let filterPinch = CIFilter(name:"CICrystallize")!
            
            filterPinch.setValue(CGVector.init(dx: 100, dy: 100), forKey: "inputCenter")
            filterPinch.setValue(10, forKey: "inputRadius")
            // We only want to apply the filter to the face, not the entire image.
            // So we use cropped function to only extract the face
            filterPinch.setValue(retImage.cropped(to: f.bounds), forKey: kCIInputImageKey)
            filterPinch.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
            let temp = filterPinch.outputImage!
            
            // We use combineFilter to put the cropped image back to its original image
            let combinedFilter = CIFilter(name: "CISourceOverCompositing")!
            combinedFilter.setValue(temp, forKey: "inputImage")
            combinedFilter.setValue(retImage, forKey: "inputBackgroundImage")
            let combineImage = combinedFilter.outputImage!
            
            
            let leftEyeFilter = CIFilter(name: "CIHoleDistortion")!
            leftEyeFilter.setValue(5, forKey: "inputRadius")
            leftEyeFilter.setValue(combineImage, forKey: "inputImage")
            leftEyeFilter.setValue(CIVector(cgPoint: leftEyeCenter), forKey: "inputCenter")
            let leftImage = leftEyeFilter.outputImage!
            
            
            let rightEyeFilter = CIFilter(name: "CIHoleDistortion")!
            rightEyeFilter.setValue(5, forKey: "inputRadius")
            rightEyeFilter.setValue(leftImage, forKey: "inputImage")
            rightEyeFilter.setValue(CIVector(cgPoint: rightEyeCenter), forKey: "inputCenter")
            let rightImage = rightEyeFilter.outputImage!
            
            let mouthFilter = CIFilter(name: "CIHoleDistortion")!
            mouthFilter.setValue(8, forKey: "inputRadius")
            mouthFilter.setValue(rightImage, forKey: "inputImage")
            mouthFilter.setValue(CIVector(cgPoint: mouthCenter), forKey: "inputCenter")
            retImage = mouthFilter.outputImage!
        }
        
        return retImage
    }
    
    //MARK: get faces using CIDetector
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation,
                        CIDetectorEyeBlink:true,
                        CIDetectorAccuracy:CIDetectorAccuracyHigh,
                        CIDetectorSmile:true] as [String : Any]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
    //MARK: Process image output
    func processImage(inputImage:CIImage) -> CIImage{
        
        // detect faces
        let f = getFaces(img: inputImage)
        if f.count == 0 { return inputImage }
        
        //otherwise apply the filters to the faces
        return applyFiltersToFaces(inputImage: inputImage, features: f)
    }
    
    @IBAction func switchCamera(_ sender: UIButton) {
        self.videoManager.toggleCameraPosition()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.videoManager.stop()
    }
    
    
}

