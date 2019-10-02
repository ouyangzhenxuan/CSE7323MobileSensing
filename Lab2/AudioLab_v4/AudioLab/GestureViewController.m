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
#define FDIFF 25
#define SDIFF 20

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

// Lazy instantiation for all properties
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

-(NSNumber*)sliderValue{
    if(!_sliderValue)
        _sliderValue = @20000.0;
    return _sliderValue;
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

// When Slider Change, change the content of the label to show new value
// Also reset the count number to 0 when playing frequency is changed
- (IBAction)sliderChange:(UISlider *)sender {
    self.sliderValue = @(sender.value);
    self.countUpdate =0;
}

// Label's setter function to set its text as slider's value
- (void)setSliderValue:(NSNumber *)sliderValue{
    _sliderValue = sliderValue;
    self.sliderValueLabel.text = [NSString stringWithFormat:@"%@", _sliderValue];
}

#pragma mark VC Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set countUpdate to 0 so that it starts count when open the view
    self.countUpdate = 0;
    // Set fft graphs displayed on button half of the screen
    [self.graphHelper setScreenBoundsBottomHalf];
    
    // Set slider min, max and default value
    self.sliderFrequency.maximumValue = 20000.0;
    self.sliderFrequency.minimumValue = 15000.0;
    self.sliderFrequency.value = 20000.0;
    
    // Set inputBlock
    __block GestureViewController * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
        
    }];
    
    // Set outputBlock to play sine wave based on the slider value
    __block float frequency = self.sliderFrequency.value;
    __block float phase = 0.0;
    __block float samplingRate = self.audioManager.samplingRate;
    
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        // Whenever slider value change, change the frequency to play corresponding sine wave
        frequency =[self.sliderValue floatValue];
        double phaseIncrement = 2*M_PI*frequency/samplingRate;
        double sineWaveReapteMax= 2*M_PI;
        for(int i =0;i<numFrames;i++){
            data[i] = sin(phase);
            phase+=phaseIncrement;
            
            if(phase>=sineWaveReapteMax) phase -=sineWaveReapteMax;
        }
    }];
    
    // Play audioManager
    [self.audioManager play];
}

- (void) setDefault{
    
}

#pragma mark GLK Inherited Functions
//  Update funciton
- (void)update{
    
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
    
    // Zoom in the fft graph to the place where frequency is between 15k - 20k Hz
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
    
    // Call funciton to calculate peak index and get frequency value on both sides
    [self getOriginalFrequencyValue:zoomfft];
    // Call function to calculate Doppler Effect to display gesture on the screen
    [self calculateDopplerEffect:zoomfft];
    
    // Graph the Zoom in FFT data
    [self.graphHelper setGraphData:zoomfft
                    withDataLength:250
                     forGraphIndex:2
                 withNormalization:64.0
                     withZeroValue:-60];
    
    [self.graphHelper update]; // update the graph
    // Free those arrays
    free(arrayData);
    free(fftMagnitude);
    free(zoomfft);
}

// Function to get peak index and sides values
- (void)getOriginalFrequencyValue:(float*)zoomfft{
    
    // Increment Count
    if(self.countUpdate<10)
        self.countUpdate ++;
    
    // Because the fft values are unstable when peak frequency just gets played,
    // we want to get the frequency value 3 updates later
    // which is a very small time period that human cannot detect
    if(self.countUpdate ==3){
        
        // Get peak frequency
        float frequency =[self.sliderValue floatValue];
        
        // Calculate index and round it
        float index= (frequency/(self.audioManager.samplingRate/(float)BUFFER_SIZE) -697.0);
        self.peakIndex = lroundf(index);
        
        // Get frequency value on both sides, where the second node is for slow motion,
        // and the fifth node is for fast motion
        self.leftslow =zoomfft[self.peakIndex-2];
        self.rightslow= zoomfft[self.peakIndex+2];
        self.leftfast = zoomfft[self.peakIndex-5];
        self.rightfast = zoomfft[self.peakIndex+5];
    }
}

// Calcualte Doppler Effect using the data measured from the function above
- (void)calculateDopplerEffect:(float*)zoomfft{
    
    // After measuring the data on both sides of the peak,
    // calculate the values on those nodes again to see if they change
    if(self.countUpdate >3){
        float leftChange = zoomfft[self.peakIndex-2]-self.leftslow;
        float rightChange= zoomfft[self.peakIndex+2]-self.rightslow;
        float leftChange2 = zoomfft[self.peakIndex-5]-self.leftfast;
        float rightChange2= zoomfft[self.peakIndex+5]-self.rightfast;
        
        // if their changing differences are greater than default differences,
        // display those gestures,
        // also set the count to be -10 for displaying text on the label
        if(leftChange2>FDIFF || rightChange2>FDIFF){
            if(leftChange2>FDIFF){
                self.gesture.text = @"Away";
                self.count = -10;
            }
            if(rightChange2>FDIFF){
                self.gesture.text = @"Push";
                self.count = -10;
            }
        }
        else{
            if(leftChange>SDIFF){
                self.gesture.text = @"Away";
                self.count = -10;
            }
            if(rightChange>SDIFF){
                self.gesture.text = @"Push";
                self.count = -10;
            }
        }
    }
    
    // Increment count, after 10 updates, reset the label's text
    if(self.count<1)
        self.count ++;
    if(self.count==0)
        self.gesture.text = @"";
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

// When close the view, set output block to nil and pause audiomanager
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.audioManager setOutputBlock:nil];
    [self.audioManager pause];
    
}




@end
