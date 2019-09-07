//
//  ImageModel.m
//  SMUExampleOne
//
//  Created by Eric Larson on 1/21/15.
//  Copyright (c) 2015 Eric Larson. All rights reserved.
//

#import "ImageModel.h"

@interface ImageModel()

// make this property private
@property (strong,nonatomic) NSArray* imageNames;
@property (strong,nonatomic) NSMutableArray* imageArray;
@end


@implementation ImageModel

@synthesize imageNames = _imageNames;

-(NSArray*)imageNames{
//    NSLog(@"imageNames Method");
    if(!_imageNames){
        _imageNames = @[@"Eric1",@"Eric2",@"Eric3"];
//        UIImage *image1 = [UIImage imageNamed:@"Eric1"];
//        UIImage *image2 = [UIImage imageNamed:@"Eric2"];
//        UIImage *image3 = [UIImage imageNamed:@"Eric3"];
//        _imageNames = @[image1,image2,image3];
    }
    return _imageNames;
}

/**************************************/
- (NSMutableArray *)imageArray{
    
    NSLog(@"imageArray Method");

    if(!_imageArray){
        for(NSString *imageName in _imageNames){
            if(imageName){
                NSLog(@"Setting imageName in imageArray");
                NSLog(@"%@", imageName);
            }
            UIImage *image = [UIImage imageNamed:imageName];
            [_imageArray addObject:image];
        }
    }
    return _imageArray;
}

- (NSString*)getImageNameByIndex:(NSInteger) atIndex{
    
    NSLog(@"getImageNameByIndex Method");

    NSString *theImageName = [self.imageArray objectAtIndex:atIndex];
    return theImageName;
}

- (NSInteger)getNumbersOfImages{
    
    NSLog(@"getNumbersOfImages Method");
    
    if(!_imageArray){
        return _imageArray.count;
    }
    return 0;
}

/**************************************/

+(ImageModel*)sharedInstance{
    
    NSLog(@"sharedInstance Method");
    
    static ImageModel * _sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate,^{
        _sharedInstance = [[ImageModel alloc] init];
    });
    
    return _sharedInstance;
}

-(UIImage*)getImageWithName:(NSString *)name{
    UIImage* image = nil;
    image = [UIImage imageNamed:name];
    return image;
}

@end
