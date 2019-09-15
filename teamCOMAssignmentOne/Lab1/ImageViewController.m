//
//  ImageViewController.m
//  Lab1
//
//  Created by 梅沈潇 on 9/8/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

#import "ImageViewController.h"

@interface ImageViewController () {
    IBOutlet UIScrollView * scrollView;
}

@property (strong,nonatomic) UIImageView* imageView;


@end


@implementation ImageViewController
@synthesize imageView=_imageView;

- (void)viewDidLoad {
    [super viewDidLoad];
    //初始化滚动视图
    scrollView = [[UIScrollView alloc]init];
    CGRect scrollFrame;
    scrollFrame.origin = scrollView.frame.origin;
    scrollFrame.size = CGSizeMake(self.view.frame.size.width*2, self.view.frame.size.height*2);
    scrollView.frame = scrollFrame;


    [self.view addSubview:scrollView];

    //初始化imageview，设置图片
    self.imageView = [[UIImageView alloc]init];
    NSString* oneTime=self.imageName;
    self.imageView.image = [UIImage imageNamed:oneTime];
    self.imageView.frame = CGRectMake(0, 0, self.imageView.image.size.width, self.imageView.image.size.height);
    [scrollView addSubview:self.imageView];

    //设置代理,设置最大缩放和虽小缩放（*一定要有这句话）
    scrollView.delegate = self;
    scrollView.maximumZoomScale = 5;
    scrollView.minimumZoomScale = 0.3;

    //设置UIScrollView的滚动范围和图片的真实尺寸一致
    scrollView.contentSize = CGSizeMake(self.imageView.frame.size.width*3, self.imageView.frame.size.height*3);
    
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    [self.view setNeedsDisplay];
    
}


-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.imageView;
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
-(void)viewWillAppear:(BOOL)animated
{
    [self.timer invalidate];
    self.timer=nil;
}
@end
