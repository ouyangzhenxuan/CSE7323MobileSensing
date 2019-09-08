//
//  ImageModel.m
//  Lab1_ouyang
//
//  Created by Zhenxuan Ouyang on 9/7/19.
//  Copyright © 2019 Zhenxuan Ouyang. All rights reserved.
//

#import "ImageModel.h"

@interface ImageModel()

@property (strong, nonatomic) NSDictionary *dictionary;

@end

@implementation ImageModel
@synthesize imageNames = _imageNames;
@synthesize imageDescription = _imageDescription;

-(NSArray*)imageNames{
    
    if(!_imageNames){
        
        // allocate memory to mutable array
        _imageNames = [[NSMutableArray alloc]init];
        _imageDescription = [[NSMutableArray alloc]init];
        
        // read json file data
        NSString *path = [[NSBundle mainBundle] pathForResource:@"document" ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:nil];
        
        // dictionary or array
        _dictionary = [[NSDictionary alloc]init];
        _dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        // store data into local variable
        for(NSString* item in _dictionary.allKeys){
            [_imageNames addObject:_dictionary[item][@"Logo"]];
            if([_dictionary[item][@"Discount"] isEqual:@""]){
                if([_dictionary[item][@"Type"] isEqual:@"ComingSoon"]){
                    [_imageDescription addObject:@"Coming soon!"];
                }else{
                    [_imageDescription addObject:@"Discount inside!"];
                }
            }else{
                [_imageDescription addObject:[_dictionary[item][@"Discount"] stringByAppendingString:@" off"]];
//                [_dictionary[item][@"Discount"] stringByAppendingString:@" off"]
            }
            NSLog(@"%@", [_imageNames objectAtIndex:0]);
        }
    }
    return _imageNames;
}

+(ImageModel*)sharedInstance{
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
