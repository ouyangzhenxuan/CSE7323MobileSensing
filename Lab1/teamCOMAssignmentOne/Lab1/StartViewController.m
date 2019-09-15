//
//  StartViewController.m
//  Lab1
//
//  Created by Zhenxuan Ouyang on 9/8/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

#import "StartViewController.h"
#import "ImageModel.h"
#import "TableViewController.h"
#import "CollectionViewController.h"

@interface StartViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentBar;
@property (weak, nonatomic) IBOutlet UIView *firstView;
@property (weak, nonatomic) IBOutlet UIView *secondView;

@property (strong, nonatomic) ImageModel *myImageModel;
@property (strong, nonatomic) TableViewController* tableController;
@property (strong, nonatomic) CollectionViewController* collectionController;
@end


@implementation StartViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    
    // Do any additional setup after loading the view.
    
    _firstView.alpha = 1;
    _secondView.alpha = 0;
}

-(ImageModel*)myImageModel{
    
    if(!_myImageModel)
        _myImageModel =[ImageModel sharedInstance];
    
    return _myImageModel;
}

- (IBAction)segmentDidChange:(UISegmentedControl *)sender {
    if(sender.selectedSegmentIndex==0){
        _firstView.alpha = 1;
        _secondView.alpha = 0;
    }else{
        _firstView.alpha = 0;
        _secondView.alpha = 1;
    }
}

- (void)delegateData:(NSArray*)sender{
    for(NSString* i in self.myImageModel.getInfo){
        if([self.myImageModel.activeState[i]isEqualToString:@"false"]){
            [self.myImageModel.activeState removeObjectForKey:i];
            [self.myImageModel.activeState setObject:@"true" forKey:i];
            self.myImageModel.activeItemNumber+=1;
        }
        if(![[sender objectAtIndex:0] isEqualToString:@"Tags"]){
            if(![self.myImageModel.getInfo[i][@"Category"] containsObject:[sender objectAtIndex:0]]){
                [self.myImageModel.activeState removeObjectForKey:i];
                [self.myImageModel.activeState setObject:@"false" forKey:i];
                self.myImageModel.activeItemNumber-=1;
                continue;
            }
        }
        if([[sender objectAtIndex:1] doubleValue] < [self.myImageModel.getInfo[i][@"No_of_Players"] doubleValue]){
            [self.myImageModel.activeState removeObjectForKey:i];
            [self.myImageModel.activeState setObject:@"false" forKey:i];
            self.myImageModel.activeItemNumber-=1;
            continue;
        }
        if([[sender objectAtIndex:2] doubleValue] < [[self.myImageModel.getInfo[i][@"Price"] substringFromIndex:1]doubleValue]){
            [self.myImageModel.activeState removeObjectForKey:i];
            [self.myImageModel.activeState setObject:@"false" forKey:i];
            self.myImageModel.activeItemNumber-=1;
            continue;
        }
        if([[sender objectAtIndex:3] isEqualToString:@"YES"]){
            if(![self.myImageModel.getInfo[i][@"Type"] isEqualToString:@"Discount"]){
                [self.myImageModel.activeState removeObjectForKey:i];
                [self.myImageModel.activeState setObject:@"false" forKey:i];
                self.myImageModel.activeItemNumber-=1;
                continue;
            }
        }
    }
    [self.tableController.tableView reloadData];
    [self.collectionController.collectionView reloadData];
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    BOOL isSSS =[[segue destinationViewController] isKindOfClass:[FilterViewController class]];
    BOOL isTTT =[[segue destinationViewController] isKindOfClass:[TableViewController class]];
    BOOL isCCC =[[segue destinationViewController] isKindOfClass:[CollectionViewController class]];
    if(isSSS){
        FilterViewController*controller = [segue destinationViewController];
        controller.delegate=self;
    }
    if(isTTT){
        self.tableController=[segue destinationViewController];
    }
    if(isCCC){
        self.collectionController=[segue destinationViewController];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
