//
//  FFTModel.h
//  AudioLab
//
//  Created by 梅沈潇 on 9/30/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import <Foundation/Foundation.h>
#define BUFFER_SIZE 2048*4*4
#define BUFFER_SIZE2 2048
#define FDIFF 25
#define SDIFF 15

NS_ASSUME_NONNULL_BEGIN

@interface FFTModel : NSObject

+(FFTModel*) sharedInstance;

-(void) start;

-(void) startGesture:(float)frequency;

-(float*) getArrayData;

-(void) changeFrequency:(float)newFrequency;

-(float*) fftData;

-(float*) gestureFFTDATA;

-(float*) getZoomFFT;

-(float*) getFrequencies;

-(void) stop;

-(BOOL) shouldLock;

- (void)getOriginalFrequencyValue;

- (NSString*)calculateDopplerEffect;
@end

NS_ASSUME_NONNULL_END
