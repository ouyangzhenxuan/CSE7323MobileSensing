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

#define BUFFER_SIZE 2048*4

@interface ViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (strong, nonatomic) AudioFileReader *fileReader;
@property (nonatomic) float* floatArray;
@property (nonatomic) float volume;
@property (weak, nonatomic) IBOutlet UILabel *maxFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *secFrequencyLabel;

@end



@implementation ViewController

#pragma mark Lazy Instantiation

-(AudioFileReader*)fileReader{
    if(!_fileReader){
        NSURL *inputFileURL = [[NSBundle mainBundle] URLForResource:@"2000_2050_sin" withExtension:@"wav"];
        _fileReader = [[AudioFileReader alloc]
                       initWithAudioFileURL:inputFileURL
                       samplingRate:self.audioManager.samplingRate
                       numChannels:self.audioManager.numOutputChannels];
    }
    return _fileReader;
}


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
    self.volume=1.0;
    // Do any additional setup after loading the view, typically from a nib.
    [self.fileReader play];
    self.fileReader.currentTime = 0.0;
    
    __block ViewController * __weak  weakSelf = self; // don't incrememt ARC'
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         //         [weakSelf.fileReader retrieveFreshAudio:data numFrames:numFrames numChannels:numChannels];
         [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
         
     }];
    
    [self.graphHelper setFullScreenBounds];
    
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
    
    [self.audioManager play];
    
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    // just plot the audio stream
    
    // get audio stream data
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    float* arrayData1 = malloc(sizeof(float)*BUFFER_SIZE);
    float* arrayData2 = malloc(sizeof(float)*BUFFER_SIZE);
    float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
    float* fftFreq = malloc(sizeof(float)*BUFFER_SIZE/2);
    float* fftMagnitude_window = malloc(sizeof(float)*BUFFER_SIZE/2);
    
    
    
    self.floatArray = malloc(sizeof(float)*20);
    [self.buffer fetchFreshData:arrayData1 withNumSamples:BUFFER_SIZE];
    [self.buffer fetchFreshData:arrayData2 withNumSamples:BUFFER_SIZE];
    
    for(NSInteger i=0;i<BUFFER_SIZE;i++){
        arrayData[i]=(arrayData1[i]=arrayData2[i])/2;
    }
    
    //send off for graphing
    [self.graphHelper setGraphData:arrayData
                    withDataLength:BUFFER_SIZE
                     forGraphIndex:1];
    
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:fftMagnitude];
    
    // graph the FFT Data
    [self.graphHelper setGraphData:fftMagnitude
                    withDataLength:BUFFER_SIZE/2
                     forGraphIndex:0
                 withNormalization:64.0
                     withZeroValue:-60];
    
    for(NSInteger i = 0;i<BUFFER_SIZE/2;i++){
        NSInteger end=i+8;
        if(end>BUFFER_SIZE/2){
            end=BUFFER_SIZE/2;
        }
        NSInteger maxIndex=i;
        for(NSInteger j = i;j<end;j++){
            if(fftMagnitude[j]>fftMagnitude[maxIndex]){
                maxIndex=j;
            }
        }
        fftMagnitude_window[i]=fftMagnitude[maxIndex];
        fftFreq[i]=maxIndex;
    }
    
    float fs=44100;
    float step=fs/(float)8192.0;
    
    
    
    NSInteger current=0;
    NSInteger count=0;
    float max_freq=0.0;
    float sec_freq=0.0;
    float secMagnitude=-999.9;
    float Magnitude=-999.9;
    for(NSInteger i = 0;i<BUFFER_SIZE/2;i++){
        if(fftFreq[i]==fftFreq[current]){
            count+=1;
        }else{
            current=i;
            count=0;
        }
        if(count>=7){
            if(fftMagnitude_window[current]>Magnitude){
                sec_freq=max_freq;
                secMagnitude=Magnitude;
                max_freq=fftFreq[i]*step;
                Magnitude=fftMagnitude_window[current];
                continue;
            }
            if(fftMagnitude_window[current]>secMagnitude){
                sec_freq=fftFreq[i]*step;
                secMagnitude=fftMagnitude_window[current];
            }
        }
    }
    
    //    for(NSInteger i = 0;i<BUFFER_SIZE/2;i++){
    //        if(fftMagnitude[i]>Magnitude){
    //            current=i;
    //            Magnitude=fftMagnitude[i];
    //        }
    //    }
    
    NSString *maxFrequency = [NSString stringWithFormat:@"%f", (float)max_freq];
    NSString *secFrequency = [NSString stringWithFormat:@"%f", (float)sec_freq];
    
    self.maxFrequencyLabel.text=maxFrequency;
    self.secFrequencyLabel.text=secFrequency;
    for (NSInteger i=0; i<20; i+=1) {
        float max=-999;
        for(NSInteger j=i*BUFFER_SIZE/40;j<(i+1)*BUFFER_SIZE/40;j++){
            if(fftMagnitude[j]>max){
                max=fftMagnitude[j];
            }
        }
        self.floatArray[i]=max;
    }
    
    //    [self.graphHelper setGraphData:fftMagnitude_window
    //                    withDataLength:BUFFER_SIZE/2
    //                     forGraphIndex:1
    //                 withNormalization:64.0
    //                     withZeroValue:-60];
    
    //    [self.graphHelper setGraphData:self.floatArray
    //                    withDataLength:20
    //                     forGraphIndex:3
    //                 withNormalization:64.0
    //                     withZeroValue:-60];
    
    [self.graphHelper update]; // update the graph
    free(arrayData);
    free(fftMagnitude);
    free(self.floatArray);
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

- (void)viewDidDisappear:(BOOL)animated{
    [self.audioManager pause];
}

@end

////
////  ViewController.m
////  AudioLab
////
////  Created by Eric Larson
////  Copyright © 2016 Eric Larson. All rights reserved.
////
//
//#import "ViewController.h"
//#import "Novocaine.h"
//#import "CircularBuffer.h"
//#import "SMUGraphHelper.h"
//#import "FFTHelper.h"
//#import "AudioFileReader.h"
//
//#define BUFFER_SIZE 2048*4
//
//@interface ViewController ()
//@property (strong, nonatomic) Novocaine *audioManager;
//@property (strong, nonatomic) CircularBuffer *buffer;
//@property (strong, nonatomic) SMUGraphHelper *graphHelper;
//@property (strong, nonatomic) FFTHelper *fftHelper;
//
//@property (strong, nonatomic) AudioFileReader *fileReader;
//@property (nonatomic) float volume;
//@property (nonatomic) float step_distance;
//
//@property (weak, nonatomic) IBOutlet UITextField *frequence1;
//@property (weak, nonatomic) IBOutlet UITextField *frequence2;
//@end
//
//
//
//@implementation ViewController
//
//-(AudioFileReader*)fileReader{
//    if(!_fileReader){
//        NSURL *inputFileURL = [[NSBundle mainBundle] URLForResource:@"500_2000_Tones" withExtension:@"wav"];
//        NSURL *inputFileURL2 = [[NSBundle mainBundle] URLForResource:@"satisfaction" withExtension:@"mp3"];
//        NSURL *inputFileURL3 = [[NSBundle mainBundle] URLForResource:@"6000" withExtension:@"wav"];
//        NSURL *inputFileURL4 = [[NSBundle mainBundle] URLForResource:@"3000" withExtension:@"wav"];
//        _fileReader = [[AudioFileReader alloc]
//                       initWithAudioFileURL:inputFileURL4
//                       samplingRate:self.audioManager.samplingRate
//                       numChannels:self.audioManager.numOutputChannels];
//    }
//    return _fileReader;
//}
//
//#pragma mark Lazy Instantiation
//-(Novocaine*)audioManager{
//    if(!_audioManager){
//        _audioManager = [Novocaine audioManager];
//    }
//    return _audioManager;
//}
//
//-(CircularBuffer*)buffer{
//    if(!_buffer){
//        _buffer = [[CircularBuffer alloc]initWithNumChannels:1 andBufferSize:BUFFER_SIZE];
//    }
//    return _buffer;
//}
//
//-(SMUGraphHelper*)graphHelper{
//    if(!_graphHelper){
//        _graphHelper = [[SMUGraphHelper alloc]initWithController:self
//                                        preferredFramesPerSecond:15
//                                                       numGraphs:2
//                                                       plotStyle:PlotStyleSeparated
//                                               maxPointsPerGraph:BUFFER_SIZE];
//    }
//    return _graphHelper;
//}
//
//-(FFTHelper*)fftHelper{
//    if(!_fftHelper){
//        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
//    }
//
//    return _fftHelper;
//}
//
//
//#pragma mark VC Life Cycle
//- (void)viewDidLoad {
//    [super viewDidLoad];
//    // Do any additional setup after loading the view, typically from a nib.
//
//
//    [self.graphHelper setFullScreenBounds];
////     [self.fileReader play];
////    __block ViewController * __weak  weakSelf = self;
////    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
////        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
////    }];
////
////    [self.audioManager play];
//
//
//    self.volume = 0.5;
//    self.fileReader.currentTime = 0.0;
//    __block ViewController * __weak  weakSelf = self; // don't incrememt ARC'
//
//    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//         [weakSelf.fileReader retrieveFreshAudio:data numFrames:numFrames numChannels:numChannels];
//         [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
//         for(int i=0;i<numFrames*numChannels;i++){
//             data[i] = data[i]*weakSelf.volume;
//         }
//         NSLog(@"Time: %f", weakSelf.fileReader.currentTime);
//
//     }];
//    [self.fileReader play];
//    [self.audioManager play];
//}
//
//- (IBAction)restartSong:(UIButton *)sender {
//    self.fileReader = nil;
//    self.fileReader.currentTime = 0;
//}
//
//#pragma mark GLK Inherited Functions
////  override the GLKViewController update function, from OpenGLES
//- (void)update{
//    // just plot the audio stream
//
//    // get audio stream data
//    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
//    float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
//
//    float* sliding = malloc(sizeof(float)*8);
//
//    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
//
//    //send off for graphing
//    [self.graphHelper setGraphData:arrayData
//                    withDataLength:BUFFER_SIZE
//                     forGraphIndex:0];
//
//    // take forward FFT
//    [self.fftHelper performForwardFFTWithData:arrayData
//                   andCopydBMagnitudeToBuffer:fftMagnitude];
//
//    // graph the FFT Data
//    [self.graphHelper setGraphData:fftMagnitude
//                    withDataLength:BUFFER_SIZE/2
//                     forGraphIndex:1
//                 withNormalization:64.0
//                     withZeroValue:-60];
//
//    float fs = 22050;
//    self.step_distance = fs / (BUFFER_SIZE/2);
//
//    NSInteger max_magnitude = -999;
//    NSInteger max_frequency = -999;
//    int count=0;
//    for(NSInteger i=0; i<(BUFFER_SIZE/2); i++){
//        count++;
//        if(fftMagnitude[i]>=max_magnitude){
//            max_magnitude = fftMagnitude[i];
////            NSLog(@"The max magnitude is %ld", max_magnitude);
////            NSLog(@"The max magnitude is at the index %ld", i);
////            NSLog(@"The Sample Frequency is %f", fs);
////            NSLog(@"The buffer size is %d", BUFFER_SIZE);
//
//            NSLog(@"The step is %f", self.step_distance);
//            max_frequency = i * self.step_distance;
//            NSLog(@"The max frequency is %ld", max_frequency);
//        }
//    }
//
//    NSString *maxString = [NSString stringWithFormat:@"%ld", (long)max_magnitude];
//
//    NSString *maxFrequency = [NSString stringWithFormat:@"%ld", (long)max_frequency];
//
//    self.frequence1.text = maxFrequency;
//    [self.graphHelper update]; // update the graph
//
//
//    free(arrayData);
//    free(fftMagnitude);
//}
//
////  override the GLKView draw function, from OpenGLES
//- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
//    [self.graphHelper draw]; // draw the graph
//}
//
//
//@end
