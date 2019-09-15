//
//  FilterViewController.h
//  Lab1
//
//  Created by 梅沈潇 on 9/10/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

#import "ViewController.h"

NS_ASSUME_NONNULL_BEGIN


@class FilterViewController;
@protocol delegateMethod <NSObject>

-(void)delegateData:(NSArray*) sender;

@end


@interface FilterViewController : UIViewController<UIPickerViewDelegate,UIPickerViewDelegate>
@property (nonatomic, weak) id <delegateMethod> delegate;

@end


NS_ASSUME_NONNULL_END
