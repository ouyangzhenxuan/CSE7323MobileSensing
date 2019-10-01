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

@interface FFTModel()

@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;

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
    NSLog(@"SS");
    [self.audioManager play];
}

-(float*) fftData{
    [self.buffer fetchFreshData:self.arrayData withNumSamples:BUFFER_SIZE];
    [self.fftHelper performForwardFFTWithData:self.arrayData
                   andCopydBMagnitudeToBuffer:self.fftMagnitude];
    return self.fftMagnitude;
}

-(float*) getFrequencies{
    float fs=44100;
    float step=fs/(float)8192.0;
    NSInteger windowSize=50;
    float peak1=-9999.9;
    float peak2=-9999.9;
    int peakIdx1=-1;
    int peakIdx2=-1;
    for(int i=0;i<BUFFER_SIZE/2-windowSize;i++){
        int middle=i+windowSize/2;
        float maxMag=-9999.9;
        int maxIndex=i;
        for (int j=i; j<i+windowSize; j++) {
            if(self.fftMagnitude[j]>self.fftMagnitude[maxIndex]){
                maxIndex=j;
                maxMag=self.fftMagnitude[maxIndex];
            }
        }
        if(maxIndex==middle){
            if(maxMag>peak1){
                peak2=peak1;
                peakIdx2=peakIdx1;
                peak1=maxMag;
                peakIdx1=maxIndex;
                continue;
            }
            if(maxMag>peak2){
                peak2=maxMag;
                peakIdx2=maxIndex;
            }
        }
    }
    float max_freq =(peakIdx1+(self.fftMagnitude[peakIdx1+1]-self.fftMagnitude[peakIdx1-1])/((self.fftMagnitude[peakIdx1+1]+self.fftMagnitude[peakIdx1-1]-2*self.fftMagnitude[peakIdx1])*0.5))*step;
    float sec_freq;
    if(peakIdx2>0){
        sec_freq=(peakIdx2+(self.fftMagnitude[peakIdx2+1]-self.fftMagnitude[peakIdx2-1])/((self.fftMagnitude[peakIdx2+1]+self.fftMagnitude[peakIdx2-1]-2*self.fftMagnitude[peakIdx2])*0.5))*step;
    }else{
        sec_freq=peakIdx2*step;
    }
    self.returnData[0]=max_freq;
    self.returnData[1]=sec_freq;
    return self.returnData;
}

-(void)clear{
    
//    free(self.arrayData);
//    free(self.fftMagnitude);
//    free(self.returnData);
}

- (void)dealloc
{
    free(self.arrayData);
    free(self.fftMagnitude);
    free(self.returnData);
}

@end
