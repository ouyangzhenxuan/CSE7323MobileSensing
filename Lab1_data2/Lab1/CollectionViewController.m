//
//  CollectionViewController.m
//  Lab1
//
//  Created by Zhenxuan Ouyang on 9/8/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

#import "CollectionViewController.h"
#import "ImageModel.h"
#import "ViewController.h"

@interface CollectionViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) NSArray* imageArray;
@property (strong, nonatomic) NSArray* labelArray;

@property (strong, nonatomic) NSMutableDictionary* dict;
@property (strong, nonatomic) ImageModel *myImageModel;

@end

@implementation CollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (NSDictionary*)dict{
    if(!_dict){
        _dict=[self.myImageModel getInfo];
    }
    return _dict;
}

-(ImageModel*)myImageModel{
    
    if(!_myImageModel)
        _myImageModel =[ImageModel sharedInstance];
    
    return _myImageModel;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.myImageModel.activeItemNumber;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    NSMutableArray* names=[[NSMutableArray alloc] init];
    
    for(NSString* i in self.dict){
        if([self.myImageModel.activeState[i]isEqualToString:@"true"]){
            [names addObject:i];
        }
    }
    //
    NSLog(@"laolaolao%lu", (unsigned long)[self.myImageModel.getInfo count]);
    NSLog(@"laolaolao%lu", (unsigned long)[names count]);
    NSString* name=[names objectAtIndex:indexPath.row];
    
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell_ID" forIndexPath:indexPath];
    
    // identify the view with tag number
    UIImageView* imageView = (UIImageView*)[cell viewWithTag:100];
    UILabel* labelView = (UILabel*)[cell viewWithTag:101];
    
    // load content inside the view
    imageView.image = [self.myImageModel getImageWithName:self.myImageModel.getInfo[name][@"Logo"]];
    labelView.text = self.myImageModel.getInfo[name][@"Type"];
    
    if([self.myImageModel.getInfo[name][@"Type"]isEqualToString:@"Hot"]){
        labelView.backgroundColor= [UIColor orangeColor];
    }else if([self.myImageModel.getInfo[name][@"Type"] isEqualToString:@"ComingSoon"]){
        labelView.backgroundColor= [UIColor greenColor];
    }else{
        NSLog(@"nmd%@", self.myImageModel.getInfo[name][@"Type"]);
        
        labelView.backgroundColor= [UIColor redColor];
    }
    cell.backgroundColor = UIColor.blackColor;
    
    // always allow verticala scroller
    collectionView.alwaysBounceVertical = YES;
    return cell;
    
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    UICollectionViewCell* cell = (UICollectionViewCell*)sender;
    ViewController *vc = [segue destinationViewController];
    NSMutableArray* activeItems=[[NSMutableArray alloc]init];
    for (NSString* i in self.myImageModel.imageTitle){
        if([self.myImageModel.activeState[i]isEqualToString:@"true"]){
            [activeItems addObject:i];
        }
    }
    NSIndexPath *indexPath=[self.collectionView indexPathForCell:cell];
    vc.product= self.myImageModel.getInfo[[activeItems objectAtIndex:indexPath.row]];
}

//-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
//    UICollectionViewCell* cell = (UICollectionViewCell*)sender;
//    ViewController *vc = [segue destinationViewController];
//    NSIndexPath *indexPath=[self.collectionView indexPathForCell:cell];
//    vc.product= self.myImageModel.getInfo[self.myImageModel.imageTitle[indexPath.row]];
//}

@end
