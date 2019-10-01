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
#import "PeakFinder.h"

#define BUFFER_SIZE 2048*4*8

@interface ViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (strong, nonatomic) AudioFileReader *fileReader;
@property (nonatomic) bool isLock;
@property (nonatomic) NSInteger lockCount;
@property (nonatomic) float lastFrequency;
@property (nonatomic) float* floatArray;
@property (nonatomic) float volume;
@property (weak, nonatomic) IBOutlet UILabel *maxFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *secFrequencyLabel;

@property (strong, nonatomic) PeakFinder* peakFinder;

@end



@implementation ViewController

#pragma mark Lazy Instantiation

-(AudioFileReader*)fileReader{
    if(!_fileReader){
        NSURL *inputFileURL = [[NSBundle mainBundle] URLForResource:@"800_1000" withExtension:@"wav"];
        _fileReader = [[AudioFileReader alloc]
                       initWithAudioFileURL:inputFileURL
                       samplingRate:self.audioManager.samplingRate
                       numChannels:self.audioManager.numOutputChannels];
    }
    return _fileReader;
}

-(PeakFinder*)peakFinder{
    if(!_peakFinder){
        _peakFinder = [[PeakFinder alloc]initWithFrequencyResolution:(((float)self.audioManager.samplingRate) / ((float)(BUFFER_SIZE)))];
    }
    return _peakFinder;
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
    self.lockCount=0;
    // Do any additional setup after loading the view, typically from a nib.
    [self.fileReader play];
    self.fileReader.currentTime = 0.0;
    self.isLock=false;
    __block ViewController * __weak  weakSelf = self; // don't incrememt ARC'
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
//                  [weakSelf.fileReader retrieveFreshAudio:data numFrames:numFrames numChannels:numChannels];
         [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
         
     }];
    
    [self.graphHelper setFullScreenBounds];
    
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
//
    [self.audioManager play];
    
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    // just plot the audio stream
    
    
    
    if(self.isLock){
        if(self.lockCount>30){
            return;
        }
    }
    
    // get audio stream data
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
//    float* arrayData1 = malloc(sizeof(float)*BUFFER_SIZE);
//    float* arrayData2 = malloc(sizeof(float)*BUFFER_SIZE);
    float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
    float* fftFreq = malloc(sizeof(float)*BUFFER_SIZE/2);
    float* fftMagnitude_window = malloc(sizeof(float)*BUFFER_SIZE/2);
    
    int max_index = 0;
    int sec_index = 0;
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
//    [self.buffer fetchFreshData:arrayData1 withNumSamples:BUFFER_SIZE];
//    [self.buffer fetchFreshData:arrayData2 withNumSamples:BUFFER_SIZE];
    
//    for(NSInteger i=0;i<BUFFER_SIZE;i++){
//        arrayData[i]=(arrayData1[i]+arrayData2[i])/2;
//    }
    
    self.floatArray = malloc(sizeof(float)*20);
    
    
    
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:fftMagnitude];
    
    //send off for graphing
    [self.graphHelper setGraphData:arrayData
                    withDataLength:BUFFER_SIZE
                     forGraphIndex:0];
    
    // graph the FFT Data
    [self.graphHelper setGraphData:fftMagnitude
                    withDataLength:BUFFER_SIZE/2
                     forGraphIndex:1
                 withNormalization:64.0
                     withZeroValue:-60];
    
    //    fftFreq[0]=0;
    //    for(NSInteger i = 1;i<BUFFER_SIZE/2-1;i++){
    //        fftFreq[i]=i+(fftMagnitude[i+1]-fftMagnitude[i-1])/((fftMagnitude[i+1]+fftMagnitude[i-1]-2*fftMagnitude[i])*0.5);
    //    }
    //    fftFreq[BUFFER_SIZE/2-1]=BUFFER_SIZE/2-1;
    
    for(NSInteger i = 0;i<BUFFER_SIZE/2;i++){
        NSInteger end=i+60;
        if(end>BUFFER_SIZE/2){
            end=BUFFER_SIZE/2;
        }
        NSInteger maxIndex=i;
        for(NSInteger j = i;j<end;j++){
            if(fftMagnitude[j]>fftMagnitude[maxIndex]){
                maxIndex=j;
            }
        }
        // fftMagnitude_window[i]: store the max magnitude of current window #i
        fftMagnitude_window[i]=fftMagnitude[maxIndex];
        // fftFreq[i]: store the max magnitude index of current window #i
        fftFreq[i]=maxIndex;
    }
    
    //    [self.graphHelper setGraphData:fftFreq
    //                    withDataLength:BUFFER_SIZE/2
    //                     forGraphIndex:0
    //                 withNormalization:64.0
    //                     withZeroValue:-60];
    //
    float fs=44100;
    float bufferSize = (float) BUFFER_SIZE;
    float step=fs/bufferSize;
    
    
    NSLog(@"%fid", fftFreq[100]);
    
    NSInteger current=0;
    NSInteger count=0;
    float max_freq=0.0;
    float sec_freq=0.0;
    float secMagnitude=-99.0;
    float Magnitude=-99.0;
    
//    float secMagnitude=0.0;
//    float Magnitude=0.0;
    
    //      return type: index, frequency, magnitude, and list of harmonics
//    NSArray* peakArray = [self.peakFinder getFundamentalPeaksFromBuffer:fftMagnitude withLength:BUFFER_SIZE/2 usingWindowSize:150 andPeakMagnitudeMinimum:5 aboveFrequency:100];
//    NSLog(@"The peak array is %@", peakArray[0]);
//    if(peakArray){
//        Peak *peak1 = (Peak*)peakArray[0];
//        if(peakArray.count>1){
//            Peak *peak2 = (Peak*)peakArray[1];
//            sec_freq = peak2.frequency;
//            secMagnitude = peak2.magnitude;
//            self.secFrequencyLabel.text = [NSString stringWithFormat:@"%.1f Hz   %.1f dB",sec_freq,secMagnitude];
//        }
//        max_freq = peak1.frequency;
//        Magnitude = peak1.magnitude;
//        self.maxFrequencyLabel.text = [NSString stringWithFormat:@"%.1f Hz   %.1f dB",max_freq,Magnitude];
//        NSLog(@"The max freq is %f", Magnitude);
//    }
    
    
    for(NSInteger i = 0;i<BUFFER_SIZE/2;i++){
        if(fftFreq[i]==fftFreq[current]){
            count+=1;
        }else{
            current=i;
            count=0;
        }
        if(count>=59){
            if(fftMagnitude_window[current]>Magnitude){
                sec_freq=max_freq;
                secMagnitude=Magnitude;

                NSInteger idx=fftFreq[current];
                max_freq=(idx+(fftMagnitude[idx+1]-fftMagnitude[idx-1])/((fftMagnitude[idx+1]+fftMagnitude[idx-1]-2*fftMagnitude[idx])*0.5))*step;

                max_freq=fftFreq[i]*step;
                max_index = fftFreq[current];
                Magnitude=fftMagnitude_window[current];
                NSLog(@"The max_freq is %f, the Manitude is %f", max_freq, Magnitude);
                NSLog(@"The sec_freq is %f, the Manitude is %f", sec_freq, secMagnitude);
                continue;
            }
            if(fftMagnitude_window[current]>secMagnitude){
                NSInteger idx=fftFreq[current];
                sec_freq=(idx+(fftMagnitude[idx+1]-fftMagnitude[idx-1])/((fftMagnitude[idx+1]+fftMagnitude[idx-1]-2*fftMagnitude[idx])*0.5))*step;

                sec_index = fftFreq[current];

                sec_freq=fftFreq[i]*step;
                secMagnitude=fftMagnitude_window[current];
            }
        }
    }
    
//    max_freq=(max_index+(fftMagnitude[max_index+1]-fftMagnitude[max_index-1])/((fftMagnitude[max_index+1]+fftMagnitude[max_index-1]-2*fftMagnitude[max_index])*0.5))*step;
//
//    sec_freq=(sec_index+(fftMagnitude[sec_index+1]-fftMagnitude[sec_index-1])/((fftMagnitude[sec_index+1]+fftMagnitude[sec_index-1]-2*fftMagnitude[sec_index])*0.5))*step;
    
    NSString *maxFrequency = [NSString stringWithFormat:@"%.2f", (float)max_freq];
    NSString *secFrequency = [NSString stringWithFormat:@"%.2f", (float)sec_freq];
    
    if(max_freq==self.lastFrequency){
        self.lockCount+=1;
    }else{
        self.lastFrequency=max_freq;
    }
    
    self.maxFrequencyLabel.text=maxFrequency;
    self.secFrequencyLabel.text=secFrequency;
    
//    for (NSInteger i=0; i<20; i+=1) {
//        float max=-999;
//        for(NSInteger j=i*BUFFER_SIZE/40;j<(i+1)*BUFFER_SIZE/40;j++){
//            if(fftMagnitude[j]>max){
//                max=fftMagnitude[j];
//            }
//        }
//        self.floatArray[i]=max;
//    }
    
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
    free(fftFreq);
    free(fftMagnitude_window);
    free(self.floatArray);
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

- (void)viewDidDisappear:(BOOL)animated{
    [self.audioManager pause];
}
- (IBAction)lock:(UIButton *)sender {
    self.isLock=true;
    self.lockCount=0;
}

- (IBAction)unlock:(id)sender {
    self.isLock=false;
}

@end
