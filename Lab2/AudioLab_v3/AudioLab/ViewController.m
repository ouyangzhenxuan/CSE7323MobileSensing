//
//  ViewController.m
//  AudioLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import "ViewController.h"
#import "SMUGraphHelper.h"
#import "AudioFileReader.h"
#import "FFTModel.h"

@interface ViewController ()
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) AudioFileReader *fileReader;
@property (nonatomic) bool isLock;
@property (nonatomic) NSInteger lockCount;
@property (nonatomic) float lastFrequency;
@property (nonatomic) float* floatArray;
@property (nonatomic) float* freqs;
@property (nonatomic) float volume;
@property (nonatomic) float max_freq;
@property (nonatomic) float pre_max_freq;
@property (nonatomic) float sec_freq;
@property (nonatomic) float pre_sec_freq;
@property (nonatomic) float set_max_freq;
@property (nonatomic) float set_sec_freq;
@property (strong,nonatomic) FFTModel* fftModel;
@property (weak, nonatomic) IBOutlet UILabel *maxFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *secFrequencyLabel;


@end



@implementation ViewController

#pragma mark Lazy Instantiation

-(FFTModel*)fftModel{
    if(!_fftModel){
        _fftModel=[FFTModel sharedInstance];
    }
    return _fftModel;
}


//-(AudioFileReader*)fileReader{
//    if(!_fileReader){
//        NSURL *inputFileURL = [[NSBundle mainBundle] URLForResource:@"600_700_sin" withExtension:@"wav"];
//        _fileReader = [[AudioFileReader alloc]
//                       initWithAudioFileURL:inputFileURL
//                       samplingRate:self.audioManager.samplingRate
//                       numChannels:self.audioManager.numOutputChannels];
//    }
//    return _fileReader;
//}

-(SMUGraphHelper*)graphHelper{
    if(!_graphHelper){
        _graphHelper = [[SMUGraphHelper alloc]initWithController:self
                                        preferredFramesPerSecond:15
                                                       numGraphs:1
                                                       plotStyle:PlotStyleSeparated
                                               maxPointsPerGraph:BUFFER_SIZE];
    }
    return _graphHelper;
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

    self.sec_freq=0;
    self.max_freq=0;
    
    [self.fftModel start];
    
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    dispatch_queue_t serialQueue = dispatch_queue_create("com.blah.queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(serialQueue, ^{
        float* fftMagnitude = [self.fftModel fftData];
        [self.graphHelper setGraphData:fftMagnitude
                        withDataLength:BUFFER_SIZE/2
                         forGraphIndex:0
                     withNormalization:64.0
                         withZeroValue:-60];
    });
    dispatch_async(serialQueue, ^{
        self.freqs=[self.fftModel getFrequencies];
    });
    dispatch_async(serialQueue, ^{
        self.pre_max_freq=self.max_freq;
        self.pre_sec_freq=self.sec_freq;
        self.max_freq=self.freqs[0];
        self.sec_freq=self.freqs[1];
        
    });
    dispatch_async(serialQueue, ^{
        if(!self.set_max_freq){
            self.set_max_freq=self.max_freq;
            self.set_sec_freq=self.sec_freq;
        }else{
            if(self.set_max_freq-self.max_freq<2&&self.set_max_freq-self.max_freq>-2){
                self.lockCount=0;
            }else{
                if(self.pre_max_freq-self.max_freq<2&&self.pre_max_freq-self.max_freq>-2){
//                    if(self.pre_sec_freq-self.sec_freq<2&&self.pre_sec_freq-self.sec_freq>-2){
                        self.lockCount+=1;
//                    }else{
//                        self.lockCount=0;
//                    }
                }else{
                    self.lockCount=0;
                }
            }
        }
    });
    dispatch_async(serialQueue, ^{
//        if(self.lockCount>10){
            dispatch_async(dispatch_get_main_queue(), ^{

                NSString* maxFrequency = [NSString stringWithFormat:@"%.2f", (float)self.max_freq];
                NSString* secFrequency = [NSString stringWithFormat:@"%.2f", (float)self.sec_freq];

                self.maxFrequencyLabel.text=maxFrequency;
                self.secFrequencyLabel.text=secFrequency;
            });
//        }
    });
    dispatch_async(serialQueue, ^{
        [self.graphHelper update];
    });
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

- (void)viewDidDisappear:(BOOL)animated{
//    [self.audioManager pause];
}
- (IBAction)lock:(UIButton *)sender {
    self.isLock=true;
    self.lockCount=0;
}

- (IBAction)unlock:(id)sender {
    self.isLock=false;
}

@end
