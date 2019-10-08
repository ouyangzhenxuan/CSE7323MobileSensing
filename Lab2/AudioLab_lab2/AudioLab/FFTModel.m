//
//  FFTModel.m
//  AudioLab
//
//  Created by 梅沈潇 on 9/30/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import "FFTModel.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "FFTHelper.h"
#import <Accelerate/Accelerate.h>

@interface FFTModel()

@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;

@property (nonatomic) unsigned long peakIdx1;
@property (nonatomic) unsigned long peakIdx2;
@property (nonatomic) unsigned long count;
@property (nonatomic) unsigned long prePeakIdx1;
@property (nonatomic) unsigned long prePeakIdx2;

@property (nonatomic) float* arrayData;
@property (nonatomic) float* fftMagnitude;
@property (nonatomic) float* returnData;

@property (strong, nonatomic) CircularBuffer *buffer2;
@property (strong, nonatomic) FFTHelper *fftHelper2;
@property (nonatomic) float* arrayData2;
@property (nonatomic) float* fftMagnitude2;
@property (nonatomic) float* zoomfft;

// variables for doppler effects
@property (nonatomic) float frequencyValue;
@property (nonatomic) int peakIndex;
@property (nonatomic) float leftslow;
@property (nonatomic) float rightslow;
@property (nonatomic) float leftfast;
@property (nonatomic) float rightfast;
@property (nonatomic) int countLabel;
@property (nonatomic) int countUpdate;
@property (nonatomic) NSString* label;


@end

// Lazy instantiation for all properties
@implementation FFTModel
- (NSString *)label{
    if(!_label)
        _label = @"";
    return _label;
}
- (int)countLabel{
    if(!_countLabel)
        _countLabel=0;
    return _countLabel;
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
- (float *)zoomfft{
    if(!_zoomfft)
        _zoomfft = malloc(sizeof(float)*300);
    return _zoomfft;
}
- (float)frequencyValue{
    if(!_frequencyValue)
        _frequencyValue = 20000;
    return _frequencyValue;
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

-(CircularBuffer*)buffer2{
    if(!_buffer2){
        _buffer2 = [[CircularBuffer alloc]initWithNumChannels:1 andBufferSize:BUFFER_SIZE2];
    }
    return _buffer2;
}

-(FFTHelper*)fftHelper{
    if(!_fftHelper){
        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
    }
    
    return _fftHelper;
}

-(FFTHelper*)fftHelper2{
    if(!_fftHelper2){
        _fftHelper2 = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE2];
    }
    
    return _fftHelper2;
}


-(float*)returnData{
    if(!_returnData){
        _returnData=malloc(sizeof(float)*2);
    }
    return _returnData;
}

-(float*)arrayData{
    if(!_arrayData){
        _arrayData=malloc(sizeof(float)*BUFFER_SIZE);
    }
    return _arrayData;
}

-(float*)fftMagnitude{
    if(!_fftMagnitude){
        _fftMagnitude=malloc(sizeof(float)*BUFFER_SIZE/2);
    }
    return _fftMagnitude;
}

-(float*)arrayData2{
    if(!_arrayData2){
        _arrayData2=malloc(sizeof(float)*BUFFER_SIZE2);
    }
    return _arrayData2;
}

-(float*)fftMagnitude2{
    if(!_fftMagnitude2){
        _fftMagnitude2=malloc(sizeof(float)*BUFFER_SIZE2/2);
    }
    return _fftMagnitude2;
}

-(unsigned long)peakIdx1{
    if(!_peakIdx1){
        _peakIdx1=0;
    }
    return _peakIdx1;
}

-(unsigned long)peakIdx2{
    if(!_peakIdx2){
        _peakIdx2=0;
    }
    return _peakIdx2;
}

-(unsigned long)prePeakIdx1{
    if(!_prePeakIdx1){
        _prePeakIdx1=0;
    }
    return _prePeakIdx1;
}

-(unsigned long)prePeakIdx2{
    if(!_prePeakIdx2){
        _prePeakIdx2=0;
    }
    return _prePeakIdx2;
}

-(unsigned long)count{
    if(!_count){
        _count=0;
    }
    return _count;
}

// function to return self instance
+(FFTModel*)sharedInstance{
    static FFTModel * _sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate,^{
        _sharedInstance = [[FFTModel alloc] init];
    });
    
    return _sharedInstance;
}

// start function to start collecting inputs for module A
-(void) start{
    __block FFTModel * __weak  weakSelf = self; // don't incrememt ARC'

    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
    [self.audioManager play];
}

// function to start outputing and inputing for module B
-(void) startGesture:(float)frequency{
    __block FFTModel * __weak  weakSelf = self; // don't incrememt ARC'
    
    // Set outputBlock to play sine wave based on the slider value
    __block float frequencies = frequency;
    self.frequencyValue = frequency;
    __block float phase = 0.0;
    __block float samplingRate = self.audioManager.samplingRate;
    
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        // Whenever slider value change, change the frequency to play corresponding sine wave
        frequencies =self.frequencyValue;
        double phaseIncrement = 2*M_PI*frequencies/samplingRate;
        double sineWaveReapteMax= 2*M_PI;
        for(int i =0;i<numFrames;i++){
            data[i] = sin(phase);
            phase+=phaseIncrement;
            
            if(phase>=sineWaveReapteMax) phase -=sineWaveReapteMax;
        }
    }];
    
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer2 addNewFloatData:data withNumSamples:numFrames];
    }];
    [self.audioManager play];
}

// when slider changes, set count to 0 and update new frequency
-(void) changeFrequency:(float)newFrequency{
    self.countUpdate =0;
    self.frequencyValue = newFrequency;
}

// get array data for module B
-(float*) getArrayData{
    [self.buffer2 fetchFreshData:self.arrayData2 withNumSamples:BUFFER_SIZE2];
    return self.arrayData2;
}

// get zoomed fft for module B
-(float*) getZoomFFT{
    for(int i =0;i<300;i++){
        self.zoomfft[i] = self.fftMagnitude2[i+647];
    }
    return self.zoomfft;
}

// get fft for module B
-(float*) gestureFFTDATA{
    [self.buffer2 fetchFreshData:self.arrayData2 withNumSamples:BUFFER_SIZE2];
    [self.fftHelper2 performForwardFFTWithData:self.arrayData2
                   andCopydBMagnitudeToBuffer:self.fftMagnitude2];
    return self.fftMagnitude2;
}

// get fft for module A
-(float*) fftData{
    [self.buffer fetchFreshData:self.arrayData withNumSamples:BUFFER_SIZE];
    [self.fftHelper performForwardFFTWithData:self.arrayData
                   andCopydBMagnitudeToBuffer:self.fftMagnitude];
    return self.fftMagnitude;
}

// algorithm to get frequencies for module A and return the result
-(float*) getFrequencies{
    float fs=44100.0;
    float step=fs/((float)BUFFER_SIZE);
    NSInteger windowSize=10;//38
    float peak1=-9999.9;
    float peak2=-9999.9;
    unsigned long peakIdx1=-1;
    unsigned long peakIdx2=-1;
    for(int i=500/step;i<BUFFER_SIZE/2-windowSize;i++){
        unsigned long middle;
        middle = windowSize/2;
        float maxMag;
        unsigned long maxIndex;
        vDSP_maxvi(&(self.fftMagnitude[i]), 1, &maxMag, &maxIndex, windowSize);
        if(maxIndex == middle){
            if(maxMag>peak1){
                peak2=peak1;
                peakIdx2=peakIdx1;
                peak1=maxMag;
                peakIdx1=maxIndex+i;
                continue;
            }
            if(maxMag>peak2){
                peak2=maxMag;
                peakIdx2=maxIndex+i;
            }
        }
    }
    self.peakIdx2=peakIdx2;
    self.peakIdx1=peakIdx1;
    float max_freq=((float)peakIdx1-(self.fftMagnitude[peakIdx1+1]-self.fftMagnitude[peakIdx1-1])/((self.fftMagnitude[peakIdx1+1]+self.fftMagnitude[peakIdx1-1]-2*self.fftMagnitude[peakIdx1])*0.5))*step;
    float sec_freq=((float)peakIdx2-(self.fftMagnitude[peakIdx2+1]-self.fftMagnitude[peakIdx2-1])/((self.fftMagnitude[peakIdx2+1]+self.fftMagnitude[peakIdx2-1]-2*self.fftMagnitude[peakIdx2])*0.5))*step;
    self.returnData[0]=max_freq;
    self.returnData[1]=sec_freq;
    return self.returnData;
}

// lock algorithm to return bool to check whether should lock result or not
-(BOOL) shouldLock
{
    if(self.peakIdx2==self.prePeakIdx2&&self.peakIdx1==self.prePeakIdx1){
        self.count+=1;
    }else{
        self.count=0;
    }
    self.prePeakIdx1=self.peakIdx1;
    self.prePeakIdx2=self.peakIdx2;
    if(self.count>=3){
        return true;
    }
    return false;
}

// Function to get peak index and sides values
- (void)getOriginalFrequencyValue{
    
    // Increment Count
    if(self.countUpdate<10)
        self.countUpdate ++;
    
    // Because the fft values are unstable when peak frequency just gets played,
    // we want to get the frequency value 3 updates later
    // which is a very small time period that human cannot detect
    if(self.countUpdate ==3){
    
        
        // Calculate index and round it
        float index= (self.frequencyValue/(self.audioManager.samplingRate/(float)BUFFER_SIZE2) -647.0);
        self.peakIndex = lroundf(index);
        
        // Get frequency value on both sides, where the second node is for slow motion,
        // and the fifth node is for fast motion
        self.leftslow =self.zoomfft[self.peakIndex-2];
        self.rightslow= self.zoomfft[self.peakIndex+2];
        self.leftfast = self.zoomfft[self.peakIndex-5];
        self.rightfast = self.zoomfft[self.peakIndex+5];
    }
}

// Calcualte Doppler Effect using the data measured from the function above
- (NSString*)calculateDopplerEffect{
    
    // After measuring the data on both sides of the peak,
    // calculate the values on those nodes again to see if they change
    if(self.countUpdate >3){
        float leftChange = self.zoomfft[self.peakIndex-2]-self.leftslow;
        float rightChange= self.zoomfft[self.peakIndex+2]-self.rightslow;
        float leftChange2 = self.zoomfft[self.peakIndex-5]-self.leftfast;
        float rightChange2= self.zoomfft[self.peakIndex+5]-self.rightfast;
        
        // if their changing differences are greater than default differences,
        // display those gestures,
        // also set the count to be -10 for displaying text on the label
        if(leftChange2>FDIFF || rightChange2>FDIFF){
            if(leftChange2>FDIFF){
                self.label = @"Away";
                self.countLabel = -10;
            }
            if(rightChange2>FDIFF){
                self.label = @"Push";
                self.countLabel = -10;
            }
        }
        else{
            if(leftChange>SDIFF){
                self.label = @"Away";
                self.countLabel = -10;
            }
            if(rightChange>SDIFF){
                self.label = @"Push";
                self.countLabel = -10;
            }
        }
    }
    
    // Increment count, after 10 updates, reset the label's text
    if(self.countLabel<1)
        self.countLabel ++;
    if(self.countLabel==0)
        self.label = @"";
    
    return self.label;
}

// free all memory
- (void)dealloc
{
    free(self.arrayData2);
    free(self.fftMagnitude2);
    free(self.zoomfft);
    free(self.arrayData);
    free(self.fftMagnitude);
    free(self.returnData);
}

// stop audiomanager
-(void) stop
{
    [self.audioManager setOutputBlock:nil];
    [self.audioManager setInputBlock:nil];
    [self.audioManager pause];
}

@end
