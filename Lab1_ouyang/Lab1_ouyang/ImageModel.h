//
//  ImageModel.h
//  Lab1_ouyang
//
//  Created by Zhenxuan Ouyang on 9/7/19.
//  Copyright © 2019 Zhenxuan Ouyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageModel : NSObject
@property (strong,nonatomic) NSMutableArray* imageNames;
@property (strong,nonatomic) NSMutableArray* imageDescription;

+(ImageModel*) sharedInstance;

//-(UIImage*)getImageWithIndex:(NSInteger)index;
-(UIImage*)getImageWithName:(NSString*)name;

@end

NS_ASSUME_NONNULL_END
