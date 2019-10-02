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


@end

@implementation FFTModel

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

-(FFTHelper*)fftHelper{
    if(!_fftHelper){
        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
    }
    
    return _fftHelper;
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

+(FFTModel*)sharedInstance{
    static FFTModel * _sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate,^{
        _sharedInstance = [[FFTModel alloc] init];
    });
    
    return _sharedInstance;
}

-(void) start{
    __block FFTModel * __weak  weakSelf = self; // don't incrememt ARC'
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
     }];
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
    [self.audioManager play];
}

-(float*) fftData{
    [self.buffer fetchFreshData:self.arrayData withNumSamples:BUFFER_SIZE];
    [self.fftHelper performForwardFFTWithData:self.arrayData
                   andCopydBMagnitudeToBuffer:self.fftMagnitude];
    return self.fftMagnitude;
}

-(float*) getFrequencies{
    float fs=44100.0;
    float step=fs/((float)BUFFER_SIZE);
    NSInteger windowSize=36;//38
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
        //maxIndex += i;
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
    float what=(self.fftMagnitude[peakIdx1+1]-self.fftMagnitude[peakIdx1-1])/((self.fftMagnitude[peakIdx1+1]+self.fftMagnitude[peakIdx1-1]-2*self.fftMagnitude[peakIdx1])*0.5)*step;
    float what2=(self.fftMagnitude[peakIdx2+1]-self.fftMagnitude[peakIdx2-1])/((self.fftMagnitude[peakIdx2+1]+self.fftMagnitude[peakIdx2-1]-2*self.fftMagnitude[peakIdx2])*0.5)*step;
//    NSLog(@"Yuanlai:%f",peakIdx1*step);
//    NSLog(@"Xianzai:%f",what);
    self.peakIdx2=peakIdx2;
    self.peakIdx1=peakIdx1;
    float max_freq=((float)peakIdx1-(self.fftMagnitude[peakIdx1+1]-self.fftMagnitude[peakIdx1-1])/((self.fftMagnitude[peakIdx1+1]+self.fftMagnitude[peakIdx1-1]-2*self.fftMagnitude[peakIdx1])*0.5))*step;
    float sec_freq=((float)peakIdx2-(self.fftMagnitude[peakIdx2+1]-self.fftMagnitude[peakIdx2-1])/((self.fftMagnitude[peakIdx2+1]+self.fftMagnitude[peakIdx2-1]-2*self.fftMagnitude[peakIdx2])*0.5))*step;
//    float max_freq=(float)peakIdx1*step;
//    float sec_freq=(float)peakIdx2*step;
    self.returnData[0]=max_freq;
    self.returnData[1]=sec_freq;
    return self.returnData;
}

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

- (void)dealloc
{
    free(self.arrayData);
    free(self.fftMagnitude);
    free(self.returnData);
}

@end
