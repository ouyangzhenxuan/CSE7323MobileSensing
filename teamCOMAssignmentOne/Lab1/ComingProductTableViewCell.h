//
//  ComingProductTableViewCell.h
//  Lab1
//
//  Created by 梅沈潇 on 9/7/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ComingProductTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *priceLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

NS_ASSUME_NONNULL_END
