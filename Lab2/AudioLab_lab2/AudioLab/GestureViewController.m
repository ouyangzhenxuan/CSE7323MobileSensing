//
//  ViewController.m
//  AudioLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import "ViewController.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "SMUGraphHelper.h"
#import "GestureViewController.h"
#import "FFTModel.h"

#define BUFFER_SIZE 2048

@interface GestureViewController ()
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (weak, nonatomic) IBOutlet UILabel *sliderValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *sliderFrequency;
@property (strong, nonatomic) NSNumber *sliderValue;
@property (weak, nonatomic) IBOutlet UILabel *gesture;
@property (strong,nonatomic) FFTModel* fftModel;

@property (nonatomic) float* arrayData;
@property (nonatomic) float* fftMagnitude;
@property (nonatomic) float* zoomfft;
@end


@implementation GestureViewController
@synthesize sliderValue = _sliderValue;

// Lazy instantiation for all properties
-(FFTModel*)fftModel{
    if(!_fftModel){
        _fftModel=[FFTModel sharedInstance];
    }
    return _fftModel;
}

-(NSNumber*)sliderValue{
    if(!_sliderValue)
        _sliderValue = @20000.0;
    return _sliderValue;
}

#pragma mark Lazy Instantiation
-(SMUGraphHelper*)graphHelper{
    if(!_graphHelper){
        _graphHelper = [[SMUGraphHelper alloc]initWithController:self
                                        preferredFramesPerSecond:15
                                                       numGraphs:3
                                                       plotStyle:PlotStyleSeparated
                                               maxPointsPerGraph:BUFFER_SIZE];
    }
    return _graphHelper;
}

// When Slider Change, change the content of the label to show new value
// Also reset the count number to 0 when playing frequency is changed
- (IBAction)sliderChange:(UISlider *)sender {
    self.sliderValue = @(sender.value);
    [self.fftModel changeFrequency:[self.sliderValue floatValue]];
}

// Label's setter function to set its text as slider's value
- (void)setSliderValue:(NSNumber *)sliderValue{
    _sliderValue = sliderValue;
    self.sliderValueLabel.text = [NSString stringWithFormat:@"%@", _sliderValue];
}

#pragma mark VC Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Set fft graphs displayed on button half of the screen
    [self.graphHelper setScreenBoundsBottomHalf];
    
    // Set slider min, max and default value
    self.sliderFrequency.maximumValue = 20000.0;
    self.sliderFrequency.minimumValue = 15000.0;
    self.sliderFrequency.value = 20000.0;
    
    //Call Start funciton to start input and output
    [self.fftModel startGesture:self.sliderFrequency.value];
}

#pragma mark GLK Inherited Functions
//  Update funciton
- (void)update{
    // initialize serial queue
    dispatch_queue_t serialQueue = dispatch_queue_create("com.blah.queue", DISPATCH_QUEUE_SERIAL);

    // get the data and graph all three graphs
    dispatch_async(serialQueue, ^{
        self.arrayData = [self.fftModel getArrayData];
        self.fftMagnitude = [self.fftModel gestureFFTDATA];
        self.zoomfft = [self.fftModel getZoomFFT];
        //send off for graphing
        [self.graphHelper setGraphData:self.arrayData
                        withDataLength:BUFFER_SIZE
                         forGraphIndex:0];
        
        // graph the FFT Data
        [self.graphHelper setGraphData:self.fftMagnitude
                        withDataLength:BUFFER_SIZE/2
                         forGraphIndex:1
                     withNormalization:64.0
                         withZeroValue:-60];
        
        // Graph the Zoom in FFT data
        [self.graphHelper setGraphData:self.zoomfft
                        withDataLength:300
                         forGraphIndex:2
                     withNormalization:64.0
                         withZeroValue:-60];
    });
    
    // call the algorithm functions to get the result and display the result on label
    dispatch_async(serialQueue, ^{
        [self.fftModel getOriginalFrequencyValue];
        // get the result from the algorithm
        NSString *gestureValue = [self.fftModel calculateDopplerEffect];
        dispatch_async(dispatch_get_main_queue(), ^{
            // update label to show the redult
            self.gesture.text = gestureValue;
        });
    });
    
    // update graphHelper each time
    dispatch_async(serialQueue, ^{
        [self.graphHelper update];
    });
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

// When close the view, set output block to nil and pause audiomanager
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.fftModel stop];
    
}




@end
