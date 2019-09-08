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
    
    // load content inside the view
    imageView.image = [self.myImageModel getImageWithName:self.myImageModel.imageNames[indexPath.row]];
    labelView.text = [self.myImageModel.imageDescription objectAtIndex:indexPath.row];
    
    cell.backgroundColor = UIColor.blackColor;
    
    // always allow verticala scroller
    collectionView.alwaysBounceVertical = YES;
    return cell;
    
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

@end
