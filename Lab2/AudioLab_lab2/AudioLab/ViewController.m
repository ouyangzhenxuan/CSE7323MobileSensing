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

@property (nonatomic) float* freqs;
@property (nonatomic) float* fftMagnitude;

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
    
    // initialize two peak frequency
    self.sec_freq=0;
    self.max_freq=0;
    
    [self.fftModel start];
    
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    
    // create a serialQueue to manage the execution of tasks
    dispatch_queue_t serialQueue = dispatch_queue_create("com.blah.queue", DISPATCH_QUEUE_SERIAL);
    
    // plot the fft graph
    [self.graphHelper setGraphData:self.fftMagnitude
                    withDataLength:BUFFER_SIZE/2
                     forGraphIndex:0
                 withNormalization:64.0
                     withZeroValue:-60];
    
    // fetch magnitude data from the fftModel, which handle data at the backend
    dispatch_async(serialQueue, ^{
        self.fftMagnitude = [self.fftModel fftData];
    });
    
    // fetch frequency data from the fftModel
    dispatch_async(serialQueue, ^{
        self.freqs=[self.fftModel getFrequencies];
    });
    
    // assign the return data to local
    dispatch_async(serialQueue, ^{
        self.max_freq=self.freqs[0];
        self.sec_freq=self.freqs[1];
    });
    
    // display the 'lock in' frequency
    dispatch_async(serialQueue, ^{
        
        // check the backend data if it should be locked
        BOOL shouldLock= [self.fftModel shouldLock];
        
        if(shouldLock){
            dispatch_async(dispatch_get_main_queue(), ^{

                NSString* maxFrequency = [NSString stringWithFormat:@"%.1f", (float)self.max_freq];
                NSString* secFrequency = [NSString stringWithFormat:@"%.1f", (float)self.sec_freq];
                
                // update the UILabel text
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

// deallocate the fftModel object
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.fftModel = nil;
}

@end
