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
    scrollView = [[UIScrollView alloc]initWithFrame:self.view.bounds];
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
    scrollView.contentSize = self.imageView.image.size;
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
