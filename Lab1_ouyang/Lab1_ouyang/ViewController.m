//
//  ViewController.m
//  Lab1_ouyang
//
//  Created by Zhenxuan Ouyang on 9/7/19.
//  Copyright © 2019 Zhenxuan Ouyang. All rights reserved.
//

#import "ViewController.h"
#import "ImageModel.h"

@interface ViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) NSArray* imageArray;
@property (strong, nonatomic) NSArray* labelArray;

@property (strong, nonatomic) ImageModel *myImageModel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    _imageArray = [[NSArray alloc] initWithObjects:@"Eric1",@"Eric2",@"Eric3",@"Eric4",@"Eric5",@"Eric6",@"Eric7",@"Eric8",@"Eric9", nil];
//    _labelArray = [[NSArray alloc] initWithObjects:@"E1",@"E2",@"E3",@"E4",@"E5",@"E6",@"E7",@"E8",@"E9", nil];
    
    
}

-(ImageModel*)myImageModel{
    
    if(!_myImageModel)
        _myImageModel =[ImageModel sharedInstance];
    
    return _myImageModel;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.myImageModel.imageNames.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell_ID" forIndexPath:indexPath];
    
    // identify the view with tag number
    UIImageView* imageView = (UIImageView*)[cell viewWithTag:100];
    UILabel* labelView = (UILabel*)[cell viewWithTag:101];
    
//    imageView.image = [UIImage imageNamed:[_imageArray objectAtIndex:indexPath.row]];
    imageView.image = [self.myImageModel getImageWithName:self.myImageModel.imageNames[indexPath.row]];
//    labelView.text = [_labelArray objectAtIndex:indexPath.row];
    labelView.text = [self.myImageModel.imageDescription objectAtIndex:indexPath.row];
    cell.backgroundColor = UIColor.blackColor;
    collectionView.alwaysBounceVertical = YES;
    return cell;
    
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

@end
