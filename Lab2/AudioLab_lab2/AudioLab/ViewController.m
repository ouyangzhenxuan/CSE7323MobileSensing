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
@property (nonatomic) float* floatArray;
@property (nonatomic) float* freqs;
@property (nonatomic) float* fftMagnitude;
@property (nonatomic) float volume;
@property (nonatomic) float max_freq;
@property (nonatomic) float sec_freq;
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
    // set volue and two max frequencies to 0
    self.volume=1.0;

    self.sec_freq=0;
    self.max_freq=0;
    
    // call model to start audiomanager
    [self.fftModel start];
    
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    // initialize serial queue
    dispatch_queue_t serialQueue = dispatch_queue_create("com.blah.queue", DISPATCH_QUEUE_SERIAL);
    
    // graph fft using seria queue
    dispatch_async(serialQueue, ^{
        self.fftMagnitude = [self.fftModel fftData];
        [self.graphHelper setGraphData:self.fftMagnitude
                        withDataLength:BUFFER_SIZE/2
                         forGraphIndex:0
                     withNormalization:64.0
                         withZeroValue:-60];
    });
    
    // get the max frequencies and set to local varianbles
    dispatch_async(serialQueue, ^{
        self.freqs=[self.fftModel getFrequencies];
    });
    dispatch_async(serialQueue, ^{
        self.max_freq=self.freqs[0];
        self.sec_freq=self.freqs[1];
    });
    
    // check whether to lock the numbers and display the result to the labels
    dispatch_async(serialQueue, ^{
        BOOL shouldLock= [self.fftModel shouldLock];
        if(shouldLock){
            dispatch_async(dispatch_get_main_queue(), ^{

                NSString* maxFrequency = [NSString stringWithFormat:@"%.1f", (float)self.max_freq];
                NSString* secFrequency = [NSString stringWithFormat:@"%.1f", (float)self.sec_freq];

                self.maxFrequencyLabel.text=maxFrequency;
                self.secFrequencyLabel.text=secFrequency;
            });
        }
    });
    dispatch_async(serialQueue, ^{
        [self.graphHelper update];
    });
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

// stop when leaving the page
- (void)viewDidDisappear:(BOOL)animated{
    [self.fftModel stop];
}


@end
