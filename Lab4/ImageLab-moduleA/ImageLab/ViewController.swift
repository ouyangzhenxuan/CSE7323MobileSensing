//
//  ViewController.swift
//  ImageLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController   {
    
    @IBOutlet weak var smileLabel: UILabel!
    @IBOutlet weak var leftEyeLabel: UILabel!
    
    @IBOutlet weak var rightEyeLabel: UILabel!
    //MARK: Class Properties
    var faceFilters : [CIFilter]! = nil
    var eyeFilters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    let pinchFilterIndex = 2
    var detector:CIDetector! = nil
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        self.setupFilters()
        
        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
        
        // create dictionary for face detection
        // HINT: you need to manipulate these proerties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyHigh, CIDetectorTracking:true,CIDetectorSmile:true,CIDetectorEyeBlink:true] as [String : Any]
        
        // setup a face detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                   context: self.videoManager.getCIContext(), // perform on the GPU is possible
            options: (optsDetector as [String : AnyObject]))
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
        
    }
    
    //MARK: Setup filtering
    func setupFilters(){
        faceFilters = []
        
        //        let filterPinch = CIFilter(name:"CIGaussianBlur")!
        let filterPinch = CIFilter(name:"CICrystallize")!
        
        filterPinch.setValue(CGVector.init(dx: 100, dy: 100), forKey: "inputCenter")
        filterPinch.setValue(10, forKey: "inputRadius")
            
        faceFilters.append(filterPinch)
        
    }
    
    //MARK: Apply filters and apply feature detectors
    func applyFiltersToFaces(inputImage:CIImage,features:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        var filterCenter = CGPoint()
        var leftEyeCenter = CGPoint()
        var rightEyeCenter = CGPoint()
        var mouthCenter = CGPoint()
        
        //        print(features.count)
        for f in features {
            //set where to apply filter
            
            
            filterCenter.x = f.bounds.midX
            filterCenter.y = f.bounds.midY
            leftEyeCenter = f.leftEyePosition
            rightEyeCenter = f.rightEyePosition
            mouthCenter = f.mouthPosition
            
            DispatchQueue.main.async {
                if(f.hasSmile){
                    print("is Smiling!!!!!")
                    self.smileLabel.text="This buddy is smiling"
                }else{
                    self.smileLabel.text="This buddy is not smiling"
                }
                
                if(f.leftEyeClosed==true){
                    self.leftEyeLabel.text="This buddy's left eye is blinking"
                }else{
                    self.leftEyeLabel.text="This buddy's left eye is not blinking"
                }
                
                if(f.rightEyeClosed==true){
                    self.rightEyeLabel.text="This buddy's right eye is blinking"
                }else{
                    self.rightEyeLabel.text="This buddy's right eye is not blinking"
                }
            }
            
            
            //do for each filter (assumes all filters have property, "inputCenter")
            for filt in faceFilters{
                filt.setValue(retImage.cropped(to: f.bounds), forKey: kCIInputImageKey)
                filt.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
                let temp = filt.outputImage!
                let combinedFilter = CIFilter(name: "CISourceOverCompositing")!
                combinedFilter.setValue(temp, forKey: "inputImage")
                combinedFilter.setValue(retImage, forKey: "inputBackgroundImage")
                var combineImage = combinedFilter.outputImage!
                
                combinedFilter.setValue(drawImagesAndText(), forKey: "inputImage")
                combinedFilter.setValue(combineImage, forKey: "inputBackgroundImage")
                combineImage = combinedFilter.outputImage!
                
                //                let eyeImage = filt.outputImage!
                let leftEyeFilter = CIFilter(name: "CIHoleDistortion")!
                //                leftEyeFilter.setValue(CGVector.init(dx: 100, dy: 100), forKey: "inputCenter")
                leftEyeFilter.setValue(5, forKey: "inputRadius")
                leftEyeFilter.setValue(combineImage, forKey: "inputImage")
                leftEyeFilter.setValue(CIVector(cgPoint: leftEyeCenter), forKey: "inputCenter")
                let leftImage = leftEyeFilter.outputImage!
                
                
                let rightEyeFilter = CIFilter(name: "CIHoleDistortion")!
                //                RightEyeFilter.setValue(CGVector.init(dx: 100, dy: 100), forKey: "inputCenter")
                rightEyeFilter.setValue(5, forKey: "inputRadius")
                rightEyeFilter.setValue(leftImage, forKey: "inputImage")
                rightEyeFilter.setValue(CIVector(cgPoint: rightEyeCenter), forKey: "inputCenter")
                
                let rightImage = rightEyeFilter.outputImage!
                
                let mouthFilter = CIFilter(name: "CIHoleDistortion")!
                //                RightEyeFilter.setValue(CGVector.init(dx: 100, dy: 100), forKey: "inputCenter")
                mouthFilter.setValue(8, forKey: "inputRadius")
                mouthFilter.setValue(rightImage, forKey: "inputImage")
                mouthFilter.setValue(CIVector(cgPoint: mouthCenter), forKey: "inputCenter")
                
                retImage = mouthFilter.outputImage!
            }
        }
        return retImage
    }
    
    func drawImagesAndText() -> CIImage{
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512))
        let img = renderer.image { ctx in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36),
                .paragraphStyle: paragraphStyle
            ]
            let string = "The best-laid schemes o'\nmice an' men gang aft agley"
            let attributedString = NSAttributedString(string: string, attributes: attrs)
            attributedString.draw(with: CGRect(x: 32, y: 32, width: 448, height: 448), options: .usesLineFragmentOrigin, context: nil)
            let mouse = UIImage(named: "mouse")
            mouse?.draw(at: CGPoint(x: 300, y: 150))
        }
        return CIImage(image: img)!
    }
    
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
        
        //        for feature in f {
        //
        //        }
        
        //        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        //        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        //        let faces = faceDetector?.features(in: inputImage)
        //
        //        for face in faces as! [CIFaceFeature] {
        //
        //            print("Found bounds are \(face.bounds)")
        //
        //            let faceBox = UIView(frame: face.bounds)
        //
        //            faceBox.layer.borderWidth = 3
        //            faceBox.layer.borderColor = UIColor.red.cgColor
        //            faceBox.backgroundColor = UIColor.clear
        //            addSubview(faceBox)
        //
        //            if face.hasLeftEyePosition {
        //                print("Left eye bounds are \(face.leftEyePosition)")
        //            }
        //
        //            if face.hasRightEyePosition {
        //                print("Right eye bounds are \(face.rightEyePosition)")
        //            }
        //        }
        
        // if no faces, just return original image
        if f.count == 0 { return inputImage }
        
        //otherwise apply the filters to the faces
        return applyFiltersToFaces(inputImage: inputImage, features: f)
    }
    
    
    
    
}

////
////  ViewController.swift
////  ImageLab
////
////  Created by Eric Larson
////  Copyright © 2016 Eric Larson. All rights reserved.
////
//
//import UIKit
//import AVFoundation
//
//class ViewController: UIViewController   {
//
//    //MARK: Class Properties
//    var filters : [CIFilter]! = nil
//    var videoManager:VideoAnalgesic! = nil
//    let pinchFilterIndex = 2
//    var detector:CIDetector! = nil
//
//    //MARK: ViewController Hierarchy
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        self.view.backgroundColor = nil
//        self.setupFilters()
//
//        self.videoManager = VideoAnalgesic.sharedInstance
//        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
//
//        // create dictionary for face detection
//        // HINT: you need to manipulate these proerties for better face detection efficiency
//        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyLow, CIDetectorTracking:true] as [String : Any]
//
//        // setup a face detector in swift
//        self.detector = CIDetector(ofType: CIDetectorTypeFace,
//                                  context: self.videoManager.getCIContext(), // perform on the GPU is possible
//            options: (optsDetector as [String : AnyObject]))
//
//        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
//
//        if !videoManager.isRunning{
//            videoManager.start()
//        }
//
//    }
//
//    //MARK: Setup filtering
//    func setupFilters(){
//        filters = []
//
////        let filterPinch = CIFilter(name:"CIBumpDistortion")!
//        let filterPinch = CIFilter(name: "CIBumpDistortion")!
//
//
////        filterPinch.setValue(-0.5, forKey: "inputScale")
//        filterPinch.setValue(CGVector.init(dx: 50, dy: 50), forKey: "inputCenter")
//        filterPinch.setValue(50, forKey: "inputRadius")
//
////        filterPinch.setValue(CGVector.init(dx: 100, dy: 100), forKey: "inputCenter")
//        filters.append(filterPinch)
//
//        let filterPinch2 = CIFilter(name:"CICircleSplashDistortion")!
//        filterPinch.setValue(CGVector.init(dx: 100, dy: 100), forKey: "inputCenter")
//        filterPinch2.setValue(75, forKey: "inputRadius")
////        filters.append(filterPinch2)
//
//
//
//    }
//
//    //MARK: Apply filters and apply feature detectors
//    func applyFiltersToFaces(inputImage:CIImage,features:[CIFaceFeature])->CIImage{
//        var retImage = inputImage
//        var filterCenter = CGPoint()
//        var lefteyeCenter = CGPoint()
//        var righteyeCenter = CGPoint()
//
//        for f in features {
//            //set where to apply filter
//
//
//            filterCenter.x = f.bounds.midX
//            filterCenter.y = f.bounds.midY
//            lefteyeCenter = f.leftEyePosition
//            righteyeCenter = f.rightEyePosition
//
////            let combinedFilter = CIFilter(name: "CISourceOverCompositing")!
////            combinedFilter.setValue(retImage, forKey: "inputImage")
////            combinedFilter.setValue(inputImageB, forKey: "inputBackgroundImage")
////            retImage = combinedFilter.outputImage!
////            inputImage.cropped(to: f.bounds)
//
//            //do for each filter (assumes all filters have property, "inputCenter")
//            for filt in filters{
//                print(f.leftEyePosition)
//                filt.setValue(retImage, forKey: kCIInputImageKey)
//                filt.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
//                // could also manipulate the radius of the filter based on face size!
//                filt.setValue(f.bounds.size.width * f.bounds.size.height / 150, forKey: "inputRadius")
//
////                if(filt.name = )
//
//                retImage = filt.outputImage!
//            }
//        }
//        return retImage
//    }
//
//    func getFaces(img:CIImage) -> [CIFaceFeature]{
//        // this ungodly mess makes sure the image is the correct orientation
//        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation]
//        // get Face Features
//        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
//
//    }
//
//    //MARK: Process image output
//    func processImage(inputImage:CIImage) -> CIImage{
//
//        // detect faces
//        let f = getFaces(img: inputImage)
//
//        // if no faces, just return original image
//        if f.count == 0 { return inputImage }
//
//        //otherwise apply the filters to the faces
//        return applyFiltersToFaces(inputImage: inputImage, features: f)
//    }
//
//
//
//
//}
//
