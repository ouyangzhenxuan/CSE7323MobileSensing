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
#import "FFTHelper.h"
#import "GestureViewController.h"

#define BUFFER_SIZE 2048
#define DOPPLER 20

@interface GestureViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (weak, nonatomic) IBOutlet UILabel *sliderValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *sliderFrequency;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (strong, nonatomic) NSNumber *sliderValue;
@property (weak, nonatomic) IBOutlet UILabel *gesture;
@property (nonatomic) int peakIndex;
@property (nonatomic) float leftslow;
@property (nonatomic) float rightslow;
@property (nonatomic) float leftfast;
@property (nonatomic) float rightfast;
@property (nonatomic) int count;
@property (nonatomic) int countUpdate;
@end



@implementation GestureViewController
@synthesize sliderValue = _sliderValue;

- (int)count{
    if(!_count)
        _count=0;
    return _count;
}

- (int)countUpdate{
    if(!_countUpdate)
        _countUpdate = 0;
    return _countUpdate;
}

- (float)leftslow{
    if(!_leftslow)
        _leftslow =0;
    return _leftslow;
}

- (float)rightslow{
    if(!_rightslow)
        _rightslow=0;
    return _rightslow;
}
- (float)leftfast{
    if(!_leftfast)
        _leftfast=0;
    return _leftfast;
}

- (float)rightfast{
    if(!_rightfast)
        _rightfast=0;
    return _rightfast;
}
- (int)peakIndex{
    if(!_peakIndex)
        _peakIndex = 0;
    return _peakIndex;
}


- (IBAction)sliderChange:(UISlider *)sender {
    self.sliderValue = @(sender.value);
    self.countUpdate =0;
}

-(NSNumber*)sliderValue{
    if(!_sliderValue)
        _sliderValue = @20000.0;
    return _sliderValue;
}

- (void)setSliderValue:(NSNumber *)sliderValue{
    _sliderValue = sliderValue;
    self.sliderValueLabel.text = [NSString stringWithFormat:@"%@", _sliderValue];
}



#pragma mark Lazy Instantiation
-(Novocaine*)audioManager{
    if(!_audioManager){
        _audioManager = [Novocaine audioManager];
    }
    return _audioManager;
}

-(CircularBuffer*)buffer{
    if(!_buffer){
        _buffer = [[CircularBuffer alloc]initWithNumChannels:1 andBufferSize:BUFFER_SIZE];
    }
    return _buffer;
}

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

-(FFTHelper*)fftHelper{
    if(!_fftHelper){
        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
    }
    
    return _fftHelper;
}


#pragma mark VC Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    self.countUpdate = 0;
    [self.graphHelper setScreenBoundsBottomHalf];
    
    self.sliderFrequency.maximumValue = 20000.0;
    self.sliderFrequency.minimumValue = 15000.0;
    self.sliderFrequency.value = 20000.0;
    
    __block GestureViewController * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
    
    __block float frequency = self.sliderFrequency.value;
    __block float phase = 0.0;
    __block float samplingRate = self.audioManager.samplingRate;
    
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        frequency =[self.sliderValue floatValue];
        double phaseIncrement = 2*M_PI*frequency/samplingRate;
        double sineWaveReapteMax= 2*M_PI;
        for(int i =0;i<numFrames;i++){
            data[i] = sin(phase);
            phase+=phaseIncrement;
            
            if(phase>=sineWaveReapteMax) phase -=sineWaveReapteMax;
        }
    }];
    
    [self.audioManager play];
}

- (void) setDefault{
    
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    // just plot the audio stream
    
    // get audio stream data
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
    //send off for graphing
    [self.graphHelper setGraphData:arrayData
                    withDataLength:BUFFER_SIZE
                     forGraphIndex:0];
    
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:fftMagnitude];
    
    
    float* zoomfft =malloc(sizeof(float)*250);
    for(int i =0;i<250;i++){
        zoomfft[i] = fftMagnitude[i+697];
    }
    
    // graph the FFT Data
    [self.graphHelper setGraphData:fftMagnitude
                    withDataLength:BUFFER_SIZE/2
                     forGraphIndex:1
                 withNormalization:64.0
                     withZeroValue:-60];
    self.countUpdate ++;
    if(self.countUpdate ==3){
        float frequency =[self.sliderValue floatValue];
        float index= (frequency/(self.audioManager.samplingRate/(float)BUFFER_SIZE) -697.0);
        self.peakIndex = lroundf(index);
        
        
        self.leftslow =zoomfft[self.peakIndex-2];
        self.rightslow= zoomfft[self.peakIndex+2];
        self.leftfast = zoomfft[self.peakIndex-5];
        self.rightfast = zoomfft[self.peakIndex+5];
        
        
    }
    
    if(self.countUpdate >3){
        float leftChange = zoomfft[self.peakIndex-2]-self.leftslow;
        float rightChange= zoomfft[self.peakIndex+2]-self.rightslow;
        float leftChange2 = zoomfft[self.peakIndex-5]-self.leftfast;
        float rightChange2= zoomfft[self.peakIndex+5]-self.rightfast;
        
        //      NSLog(@"%f %f",leftChange,rightChange);
        
        if(leftChange2>25 || rightChange2>25){
            if(leftChange2>25){
                self.gesture.text = @"Away";
                NSLog(@"Away");
                self.count = -10;
            }
            if(rightChange2>25){
                self.gesture.text = @"Push";
                NSLog(@"Push");
                self.count = -10;
            }
        }
        else{
            if(leftChange>20){
                self.gesture.text = @"Away";
                NSLog(@"Away1");
                self.count = -10;
            }
            if(rightChange>20){
                self.gesture.text = @"Push";
                NSLog(@"Push1");
                self.count = -10;
            }
        }
    }
    
    
    self.count ++;
    if(self.count==0)
        self.gesture.text = @"";
    
    
    
    [self.graphHelper setGraphData:zoomfft
                    withDataLength:250
                     forGraphIndex:2
                 withNormalization:64.0
                     withZeroValue:-60];
    
    [self.graphHelper update]; // update the graph
    free(arrayData);
    free(fftMagnitude);
}

- (void)viewWillDisappear:(BOOL)animated{
    [self.audioManager pause];
    self.audioManager.outputBlock = nil;
    
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}


@end
