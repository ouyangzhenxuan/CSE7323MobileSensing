//
//  ProductModel.m
//  Lab1
//
//  Created by 梅沈潇 on 9/7/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

#import "ProductModel.h"

@implementation ProductModel

+(ProductModel*) sharedInstance{
    static ProductModel* _sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate,^{
        _sharedInstance = [[ProductModel alloc] init];
    });
    return _sharedInstance;
}

@end
