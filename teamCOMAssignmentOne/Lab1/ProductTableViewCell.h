//
//  ProductTableViewCell.h
//  Lab1
//
//  Created by 梅沈潇 on 9/7/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProductTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *discountPriceLabel;
@property (nonatomic, weak) IBOutlet UILabel *oldPriceLabel;
@property (nonatomic, weak) IBOutlet UILabel *discountLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end

NS_ASSUME_NONNULL_END
