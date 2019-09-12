//
//  ProductModel.h
//  Lab1
//
//  Created by 梅沈潇 on 9/7/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProductModel : NSObject

@property(nonatomic,strong) NSMutableArray* titles;
@property(nonatomic,strong) NSMutableArray* discountedPrices;
@property(nonatomic,strong) NSMutableArray* oldPrices;
@property(nonatomic,strong) NSMutableArray* regions;
@property(nonatomic,strong) NSMutableArray* imageNames;

+(ProductModel*) sharedInstance;

@end

NS_ASSUME_NONNULL_END
