//
//  StartViewController.m
//  Lab1
//
//  Created by Zhenxuan Ouyang on 9/8/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

#import "StartViewController.h"

@interface StartViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentBar;
@property (weak, nonatomic) IBOutlet UIView *firstView;
@property (weak, nonatomic) IBOutlet UIView *secondView;

@end

@implementation StartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _firstView.alpha = 1;
    _secondView.alpha = 0;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
