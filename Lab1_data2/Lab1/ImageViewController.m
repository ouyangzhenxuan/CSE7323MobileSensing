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

//@property (strong,nonatomic) IBOutlet UIScrollView* scrollView;
@property (strong,nonatomic) UIImageView* imageView;


@end


@implementation ImageViewController
@synthesize imageView=_imageView;

//-(UIImageView*)imageView{
//    if(!_imageView){
//        UIImage* image=nil;
//        image = [UIImage imageNamed:self.imageName];
//        _imageView=[[UIImageView alloc] initWithImage:image];
//    }
//    NSLog(@"%@", self.imageName);
//    return _imageView;
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    //初始化滚动视图
//    scrollView = [[UIScrollView alloc]initWithFrame:self.view.bounds];
    scrollView = [[UIScrollView alloc]init];
    CGRect scrollFrame;
    scrollFrame.origin = scrollView.frame.origin;
    scrollFrame.size = CGSizeMake(self.view.frame.size.width*2, self.view.frame.size.height*2);
    scrollView.frame = scrollFrame;
//    scrollView = [[UIScrollView alloc]initWithFrame:scrollFrame];
//    scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width*3, self.view.bounds.size.height*3)];


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
//    scrollView.contentSize = self.view.bounds.size;
    scrollView.contentSize = CGSizeMake(self.imageView.frame.size.width*3, self.imageView.frame.size.height*3);

//    UIImage *imageView =
    
//    [self.scrollView addSubview:self.imageView];
//    self.scrollView.contentSize = self.imageView.image.size;
//    self.scrollView.minimumZoomScale = 0.1;
//    self.scrollView.delegate = self;
    
}

//-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
//    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
//    printf("willTransition");
//    NSLog(@"willTransition");
//    printf("%ld", (long)UIDevice.currentDevice.orientation);
//
//    // best call super just in case
//    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
//
//    // will execute before rotation
//    printf("willTransition");
//    NSLog(@"willTransition");
//    printf("%ld", [UIDevice.currentDevice orientation]);
//
//    [coordinator animateAlongsideTransition:^(id  _Nonnull context) {
//
//        // will execute during rotation
//        printf("willTransition");
//        NSLog(@"willTransition");
//        printf("%ld", (long)UIDevice.currentDevice.orientation);
//
//    } completion:^(id  _Nonnull context) {
//
//        // will execute after rotation
//        printf("willTransition");
//        NSLog(@"willTransition");
//        printf("%ld", (long)UIDevice.currentDevice.orientation);
//
//    }];
//
//}
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
//    CGRect scrollFrame;
//    scrollFrame.size = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
//    self.scrollView.frame = scrollFrame;
    [self.view setNeedsDisplay];
    
//    scrollView = [[UIScrollView alloc]initWithFrame:self.view.bounds];
//    [self.view addSubview:scrollView];
//
//    //初始化imageview，设置图片
//    self.imageView = [[UIImageView alloc]init];
//    NSString* oneTime=self.imageName;
//    self.imageView.image = [UIImage imageNamed:oneTime];
//    self.imageView.frame = CGRectMake(0, 0, self.imageView.image.size.height, self.imageView.image.size.width);
//    [scrollView addSubview:self.imageView];
//
//    //设置代理,设置最大缩放和虽小缩放（*一定要有这句话）
//    scrollView.delegate = self;
//    scrollView.maximumZoomScale = 5;
//    scrollView.minimumZoomScale = 0.3;
//
//    //设置UIScrollView的滚动范围和图片的真实尺寸一致
//    //    scrollView.contentSize = self.imageView.image.size;
//    scrollView.contentSize = CGSizeMake(self.imageView.frame.size.height*3, self.imageView.frame.size.height*3);
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
