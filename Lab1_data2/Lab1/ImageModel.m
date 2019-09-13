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
@synthesize imageNames = _imageNames;
@synthesize imageDescription = _imageDescription;

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
    NSLog(@"wotainanle%@", _imageTitle);
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

-(NSArray*)imageNames{
    
    if(!_imageNames){
        
        // allocate memory to mutable array
        _imageNames = [[NSMutableArray alloc]init];
        _imageDescription = [[NSMutableArray alloc]init];
        _imageTitle=[[NSMutableArray alloc]init];
        
        // read json file data
        NSString *path = [[NSBundle mainBundle] pathForResource:@"document" ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:nil];
        
        // dictionary or array
        _dictionary = [[NSMutableDictionary alloc]init];
        _dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        // store data into local variable
        for(NSString* item in _dictionary.allKeys){
            [_imageNames addObject:_dictionary[item][@"Logo"]];
            [_imageTitle addObject:_dictionary[item][@"Name"]];
            if([_dictionary[item][@"Discount"] isEqual:@""]){
                if([_dictionary[item][@"Type"] isEqual:@"ComingSoon"]){
                    [_imageDescription addObject:@"Coming soon!"];
                }else{
                    [_imageDescription addObject:@"Discount inside!"];
                }
            }else{
                [_imageDescription addObject:[_dictionary[item][@"Discount"] stringByAppendingString:@" off"]];
            }
//            NSLog(@"%@", [_imageNames objectAtIndex:0]);
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
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"document" ofType:@"json"];
//    NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:nil];
//
//    // dictionary or array
//    NSMutableDictionary* sdictionary = [[NSMutableDictionary alloc]init];
//    sdictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
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

////
////  ImageModel.m
////  Lab1_ouyang
////
////  Created by Zhenxuan Ouyang on 9/7/19.
////  Copyright © 2019 Zhenxuan Ouyang. All rights reserved.
////
//
//#import "ImageModel.h"
//
//@interface ImageModel()
//
////@property (strong, nonatomic) NSMutableDictionary *dictionary;
//
//@end
//
//@implementation ImageModel
//@synthesize imageNames = _imageNames;
//@synthesize imageDescription = _imageDescription;
//@synthesize dictionary = _dictionary;
//
//
//
//
//- (NSMutableArray *)imageTitle{
//    if(_imageTitle){
//        _imageTitle=[[NSMutableArray alloc]init];
//        for (NSString* i in self.dictionary) {
//            [_imageTitle addObject:i];
//        }
//    }
//    return _imageTitle;
//}
//
//-(NSMutableDictionary*)activeState{
//    if(!_activeState){
//        _activeState=[[NSMutableDictionary alloc] init];
//        for (NSString* i in self.imageTitle){
//            [_activeState setObject:@"true" forKey:i];
//        }
//    }
//    return _activeState;
//}
//
//
//
//-(NSMutableDictionary*)dictionary{
//    if(!_dictionary){
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"document" ofType:@"json"];
//        NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:nil];
//
//        // dictionary or array
//        _dictionary = [[NSMutableDictionary alloc]init];
//        _dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
//    }
//    NSLog(@"lajilajiajiaji");
//    return _dictionary;
//}
//
//-(NSArray*)imageNames{
//
//    if(!_imageNames){
//
//        // allocate memory to mutable array
//        _imageNames = [[NSMutableArray alloc]init];
//        _imageDescription = [[NSMutableArray alloc]init];
//        _imageTitle=[[NSMutableArray alloc]init];
//
//        // read json file data
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"document" ofType:@"json"];
//        NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:nil];
//
//        // dictionary or array
////        _dictionary = [[NSMutableDictionary alloc]init];
////        _dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
//
//        // store data into local variable
//        for(NSString* item in _dictionary.allKeys){
//            [_imageNames addObject:_dictionary[item][@"Logo"]];
//            [_imageTitle addObject:_dictionary[item][@"Name"]];
//            if([_dictionary[item][@"Discount"] isEqual:@""]){
//                if([_dictionary[item][@"Type"] isEqual:@"ComingSoon"]){
//                    [_imageDescription addObject:@"Coming soon!"];
//                }else{
//                    [_imageDescription addObject:@"Discount inside!"];
//                }
//            }else{
//                [_imageDescription addObject:[_dictionary[item][@"Discount"] stringByAppendingString:@" off"]];
//            }
//            NSLog(@"%@", [_imageNames objectAtIndex:0]);
//        }
//    }
//    return _imageNames;
//}
//
//+(ImageModel*)sharedInstance{
//    static ImageModel * _sharedInstance = nil;
//
//    static dispatch_once_t oncePredicate;
//
//    dispatch_once(&oncePredicate,^{
//        _sharedInstance = [[ImageModel alloc] init];
//    });
//
//    _sharedInstance.activeItemNumber=9;
//    return _sharedInstance;
//}
//
//-(UIImage*)getImageWithName:(NSString *)name{
//    UIImage* image = nil;
//    image = [UIImage imageNamed:name];
//    return image;
//}
//
//-(NSMutableDictionary*)getInfo{
//    return self.dictionary;
//}
//@end
