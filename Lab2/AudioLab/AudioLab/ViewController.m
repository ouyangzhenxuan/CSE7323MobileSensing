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
#import "AudioFileReader.h"

#define BUFFER_SIZE 2048*1

@interface ViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) FFTHelper *fftHelper;

@property (strong, nonatomic) AudioFileReader *fileReader;
@property (nonatomic) float volume;

@end



@implementation ViewController

-(AudioFileReader*)fileReader{
    if(!_fileReader){
        NSURL *inputFileURL = [[NSBundle mainBundle] URLForResource:@"500_2000_Tones" withExtension:@"wav"];
        NSURL *inputFileURL2 = [[NSBundle mainBundle] URLForResource:@"satisfaction" withExtension:@"mp3"];
        NSURL *inputFileURL3 = [[NSBundle mainBundle] URLForResource:@"500" withExtension:@"wav"];
        NSURL *inputFileURL4 = [[NSBundle mainBundle] URLForResource:@"3000" withExtension:@"wav"];
        _fileReader = [[AudioFileReader alloc]
                       initWithAudioFileURL:inputFileURL4
                       samplingRate:self.audioManager.samplingRate
                       numChannels:self.audioManager.numOutputChannels];
    }
    return _fileReader;
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
                                                       numGraphs:2
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
    
   
    [self.graphHelper setFullScreenBounds];
//     [self.fileReader play];
//    __block ViewController * __weak  weakSelf = self;
//    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
//        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
//    }];
//
//    [self.audioManager play];
    
    
    self.volume = 0.5;
    self.fileReader.currentTime = 0.0;
    __block ViewController * __weak  weakSelf = self; // don't incrememt ARC'

    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         [weakSelf.fileReader retrieveFreshAudio:data numFrames:numFrames numChannels:numChannels];
         [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
         for(int i=0;i<numFrames*numChannels;i++){
             data[i] = data[i]*weakSelf.volume;
         }
         NSLog(@"Time: %f", weakSelf.fileReader.currentTime);

     }];
    [self.fileReader play];
    [self.audioManager play];
}

- (IBAction)restartSong:(UIButton *)sender {
    self.fileReader = nil;
    self.fileReader.currentTime = 0;
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
    
    // graph the FFT Data
    [self.graphHelper setGraphData:fftMagnitude
                    withDataLength:BUFFER_SIZE/2
                     forGraphIndex:1
                 withNormalization:64.0
                     withZeroValue:-60];
    
    [self.graphHelper update]; // update the graph
    
    
    free(arrayData);
    free(fftMagnitude);
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}


@end
