//
//  ViewController.m
//  Lab1
//
//  Created by 梅沈潇 on 9/7/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

#import "ViewController.h"
#import "ImageViewController.h"

@interface ViewController (){
    
}

@property (assign,nonatomic) NSInteger pictureState;
@property (strong,nonatomic) NSArray* pictureNames;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView_detail;


@end

@implementation ViewController

-(NSArray*)pictureNames{
    if(!_pictureNames){
        _pictureNames=self.product[@"Pictures"];
    }
    return _pictureNames;
}

- (NSInteger) pictureState{
    if(!_pictureState){
        _pictureState=0;
    }
    return _pictureState;
}

- (NSDictionary*)product{
    if(!_product){
        _product = [[NSDictionary alloc] init];
    }
    return _product;
}

-(void)viewWillAppear:(BOOL)animated
{
    self.timer=[NSTimer scheduledTimerWithTimeInterval:3.0f
                                                target:self selector:@selector(changePicture:) userInfo:nil repeats:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView.image=[UIImage imageNamed:[self.product[@"Pictures"] objectAtIndex:self.pictureState]];
    self.titleLabel.text=self.product[@"Name"];
    self.title2Label.text=self.product[@"Name"];
    self.releaseLabel.text=[NSString stringWithFormat: @"Release Date: %@",self.product[@"Release_Date"]];
    self.spaceLabel.text=[NSString stringWithFormat: @"Disk Capacity: %@",self.product[@"File_Size"]];
    self.playerLabel.text=[NSString stringWithFormat: @"Suggested Player Number: %@",self.product[@"No_of_Players"]];
    if([self.product[@"Type"] isEqualToString:@"Discount"]){
        self.discountLabel.text=[NSString stringWithFormat: @"Discount: %@",self.product[@"Discount"]];
    }else if([self.product[@"Type"] isEqualToString:@"Hot"]){
        self.discountLabel.text=[NSString stringWithFormat: @"This product is hot~!"];
        self.discountLabel.textColor = [UIColor orangeColor];
    }else{
        self.discountLabel.text=@"Coming Soon~!";
        self.discountLabel.textColor = [UIColor greenColor];
    }
    NSString* price=self.product[@"Price"];
    self.priceLabel.text=[NSString stringWithFormat: @"US Price: %@", price];
    self.publisherLabel.text=[NSString stringWithFormat: @"Publisher: %@", self.product[@"Publisher"]];
    
    NSArray* category=self.product[@"Category"];
    NSString *categoryString = [category componentsJoinedByString:@"/"];
    self.categoryLabel.text=[NSString stringWithFormat: @"Category: %@", categoryString];
    // Do any additional setup after loading the view.
    
    // add subview into scrollview
    [self.view addSubview:self.scrollView_detail];
    [self.scrollView_detail addSubview:self.imageView];
    [self.scrollView_detail addSubview:self.titleLabel];
    [self.scrollView_detail addSubview:self.title2Label];
    [self.scrollView_detail addSubview:self.priceLabel];
    [self.scrollView_detail addSubview:self.spaceLabel];
    [self.scrollView_detail addSubview:self.playerLabel];
    [self.scrollView_detail addSubview:self.releaseLabel];
    [self.scrollView_detail addSubview:self.categoryLabel];
    [self.scrollView_detail addSubview:self.discountLabel];
    [self.scrollView_detail addSubview:self.publisherLabel];
    [self.scrollView_detail addSubview:self.rainbowLabel];
    
    self.scrollView_detail.delegate = self;
    self.scrollView_detail.maximumZoomScale = 0;
    self.scrollView_detail.minimumZoomScale = 0;
    self.scrollView_detail.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height*1.01);
    
}

//代理方法，告诉ScrollView要缩放的是哪个视图
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.view;
}

- (void)changePicture:(NSTimer *)timer{
    if(self.pictureState==0){
        self.pictureState=1;
    }else if(self.pictureState==1){
        self.pictureState=2;
    }else{
        self.pictureState=0;
    }
    
    self.imageView.image=[UIImage imageNamed:[self.product[@"Pictures"] objectAtIndex:self.pictureState]];
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    NSLog(@"why?");
    [self.timer invalidate];
    self.timer = nil;
    
    ImageViewController *vc = [segue destinationViewController];
    vc.imageName=[self.product[@"Pictures"] objectAtIndex:self.pictureState];
    vc.timer=self.timer;
}

@end
