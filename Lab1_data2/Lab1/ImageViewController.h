//
//  ImageViewController.h
//  Lab1
//
//  Created by 梅沈潇 on 9/9/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

#import "ViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ImageViewController : ViewController

@property (strong, nonatomic) NSString* imageName;
@property (weak,nonatomic) NSTimer* timer;

@end

NS_ASSUME_NONNULL_END
