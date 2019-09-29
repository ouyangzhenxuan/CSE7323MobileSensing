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

#define BUFFER_SIZE 2048*4*4

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

@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) int updateCount;
@property (nonatomic) int releaseCount;
@property (nonatomic) float lock_freq;
@property (nonatomic) BOOL lockMode;

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
    self.lockMode = false;
    self.volume=1.0;
    // Do any additional setup after loading the view, typically from a nib.
    [self.fileReader play];
    self.fileReader.currentTime = 0.0;

    self.lock_freq = -999.0;
    
    __block ViewController * __weak  weakSelf = self; // don't incrememt ARC'
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
//        [weakSelf.fileReader retrieveFreshAudio:data numFrames:numFrames numChannels:numChannels];
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
    float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
    float* fftFreq = malloc(sizeof(float)*BUFFER_SIZE/2);
    float* fftMagnitude_window = malloc(sizeof(float)*BUFFER_SIZE/2);


    self.floatArray = malloc(sizeof(float)*20);
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
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

    // slide window size = 8
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
        // fftMagnitude_window[i]: store the Max Magnitude of window #i
        fftMagnitude_window[i]=fftMagnitude[maxIndex];
        // fftFreq[i]: store the Max Value Index of window #i
        fftFreq[i]=maxIndex;
    }

    float fs=44100.0;
    float bufferSize = (float)BUFFER_SIZE * 1.0;
    float step=fs/bufferSize;



//    for(NSInteger i=1; i<BUFFER_SIZE/2 - 1; i++){
//        fftFreq[i] =
//    }



    NSInteger current=0;
    NSInteger count=0;
    float max_freq=0.0;
    float sec_freq=0.0;
    float secMagnitude=-999.9;
    float Magnitude=-999.9;

    NSInteger max_index = 0;
    NSInteger sec_index = 0;

    for(NSInteger i = 0;i<BUFFER_SIZE/2;i++){
        if(fftFreq[i]==fftFreq[current]){
            count+=1;
        }else{
            current=i;
            count=0;
//            self.lock_freq = 0;
//            self.updateCount = 0;
        }
        if(count>=7){
            if(fftMagnitude_window[current]>Magnitude){
                sec_freq=max_freq;
                secMagnitude=Magnitude;
                max_freq=fftFreq[i]*step;
                
                if(self.lock_freq < max_freq){
                    self.lock_freq = max_freq;
                    self.updateCount = 0;
                }
                
                Magnitude=fftMagnitude_window[current];
                max_index = fftFreq[i];
                continue;
            }
            if(fftMagnitude_window[current]>secMagnitude){
                sec_freq=fftFreq[i]*step;
                secMagnitude=fftMagnitude_window[current];
                sec_index = fftFreq[i];
            }
        }
    }
    
    if(self.lock_freq == max_freq){
        self.updateCount += 1;
    }
    if(self.updateCount<15 && self.lock_freq > max_freq){
        self.releaseCount += 1;
    }
    
    
    /*
     Quadratic Approximation: F peak = F[i] + [(M[i+1]-M[i-1])/(M[i+1]-2*M[i]+M[i-1])] * 0.5 * step
     */
    max_freq = step * (fftFreq[max_index] + 0.5*(fftMagnitude[max_index+1]-fftMagnitude[max_index-1])/(fftMagnitude[max_index+1]-2*fftMagnitude[max_index]+fftMagnitude[max_index-1]));
    
    sec_freq = step * (fftFreq[sec_index] + 0.5*(fftMagnitude[sec_index+1]-fftMagnitude[sec_index-1])/(fftMagnitude[sec_index+1]-2*fftMagnitude[sec_index]+fftMagnitude[sec_index-1]));


    NSString *maxFrequency = [NSString stringWithFormat:@"%.2f", (float)max_freq];
    NSString *secFrequency = [NSString stringWithFormat:@"%.2f", (float)sec_freq];

    self.maxFrequencyLabel.text=maxFrequency;
    self.secFrequencyLabel.text=secFrequency;
    
//
//    for (NSInteger i=0; i<20; i+=1) {
//        float max=-999;
//        for(NSInteger j=i*BUFFER_SIZE/40;j<(i+1)*BUFFER_SIZE/40;j++){
//            if(fftMagnitude[j]>max){
//                max=fftMagnitude[j];
//            }
//        }
//        self.floatArray[i]=max;
//    }

//    NSLog(@"The update count is %d", self.updateCount);
//
//    NSLog(@"The release count is %d", self.releaseCount);
//
//    NSLog(@"The current max frequency is %f", max_freq);
//    NSLog(@"The lock frequency is %f", self.lock_freq);
    
    if(self.releaseCount >= 5){
        self.lock_freq = -999.0;
        self.releaseCount = 0;
        self.updateCount = 0;
    }
    
    if(self.updateCount>=20){
        if(self.lockMode==true){
            [self.audioManager pause];
        }
        self.lock_freq = -999.0;
        self.updateCount = 0;
        self.releaseCount = 0;
        
    }else{
        
    }
    [self.graphHelper update]; // update the graph
    free(arrayData);
    free(fftMagnitude);
    free(self.floatArray);
}

- (IBAction)unlockFrequency:(UIButton *)sender {
    [self.audioManager play];
    self.lockMode = false;
    self.lock_freq = -999.0;
//    self.audioManager = nil;
//    [self update];
    [self.view reloadInputViews];
//    [super viewDidLoad];
}
- (IBAction)openLockMode:(UIButton *)sender {
    self.lockMode = true;
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

- (void)viewDidDisappear:(BOOL)animated{
    [self.audioManager pause];
}

- (IBAction)restartSong:(UIButton *)sender {
    self.fileReader = nil;
    self.fileReader.currentTime = 0;
}

@end
