//
//  FFTModel.h
//  AudioLab
//
//  Created by 梅沈潇 on 9/30/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import <Foundation/Foundation.h>
#define BUFFER_SIZE 2048*4*4

NS_ASSUME_NONNULL_BEGIN

@interface FFTModel : NSObject

+(FFTModel*) sharedInstance;

-(void) start;

-(float*) fftData;

-(float*) getFrequencies;

-(void) clear;

-(BOOL) shouldLock;

@end

NS_ASSUME_NONNULL_END
