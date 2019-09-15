//
//  ImageModel.m
//  Lab1_ouyang
//
//  Created by Zhenxuan Ouyang on 9/7/19.
//  Copyright © 2019 Zhenxuan Ouyang. All rights reserved.
//

#import "ImageModel.h"

@interface ImageModel()

@property (strong, nonatomic) NSMutableDictionary *dictionary;

@end

@implementation ImageModel

-(NSMutableDictionary*)activeState{
    if(!_activeState){
        _activeState=[[NSMutableDictionary alloc] init];
        for (NSString* i in self.dictionary){
            [_activeState setObject:@"true" forKey:i];
        }
    }
    return _activeState;
}

-(NSMutableArray*)imageTitle{
    if(!_imageTitle){
        _imageTitle=[[NSMutableArray alloc]init];
        for(NSString* i in self.dictionary){
            [_imageTitle addObject:i];
        }
    }
//    NSLog(@"wotainanle%@", _imageTitle);
    return _imageTitle;
}

-(NSMutableDictionary*)dictionary{
    if(!_dictionary){
        NSString *path = [[NSBundle mainBundle] pathForResource:@"document" ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:nil];
        
        // dictionary or array
        _dictionary = [[NSMutableDictionary alloc]init];
        _dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    }
    return _dictionary;
}


+(ImageModel*)sharedInstance{
    static ImageModel * _sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate,^{
        _sharedInstance = [[ImageModel alloc] init];
    });
    _sharedInstance.activeItemNumber=[_sharedInstance.dictionary count];
    return _sharedInstance;
}

-(UIImage*)getImageWithName:(NSString *)name{
    UIImage* image = nil;
    image = [UIImage imageNamed:name];
    return image;
}

-(NSMutableDictionary*)getInfo{
    return self.dictionary;
}
@end

