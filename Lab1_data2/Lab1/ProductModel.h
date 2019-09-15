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

@interface ProductModel : NSObject
@property (strong,nonatomic) NSMutableArray* imageNames;
@property (strong,nonatomic) NSMutableArray* imageDescription;
@property (strong,nonatomic) NSMutableArray* imageTitle;
@property (assign,nonatomic) NSInteger activeItemNumber;
@property (strong,nonatomic) NSMutableDictionary* activeState;
//@property (strong,nonatomic) NSMutableDictionary* dictionary;

+(ProductModel*) sharedInstance;

-(UIImage*)getImageWithName:(NSString*)name;

-(NSMutableDictionary*)getInfo;

@end

NS_ASSUME_NONNULL_END
