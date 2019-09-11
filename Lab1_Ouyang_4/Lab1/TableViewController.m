//
//  TableViewController.m
//  Lab1
//
//  Created by 梅沈潇 on 9/7/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

#import "TableViewController.h"
#import "ProductTableViewCell.h"
#import "NewProductTableViewCell.h"
#import "ViewController.h"
#import "ComingProductTableViewCell.h"

@interface TableViewController () <UIScrollViewDelegate>
@property (strong, nonatomic) NSDictionary* dict;

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (NSDictionary*)dict{
    if(!_dict){
        NSString *path = [[NSBundle mainBundle] pathForResource:@"document"
                                                         ofType:@"json"];
        NSData* data = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:nil];
        // dictionary or array
        _dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    }
    return _dict;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return 7;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 128;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray* names=[[NSMutableArray alloc] init];
    
    for(NSString* i in self.dict){
        [names addObject:i];
    }
    NSString* name=[names objectAtIndex:indexPath.row];
    
    UITableViewCell* cell = nil;
    if([self.dict[name][@"Type"] isEqual:@"Discount"]){
        static NSString *custom1TableIdentifier = @"ProductCell";
        ProductTableViewCell* cell1 = (ProductTableViewCell *)[tableView dequeueReusableCellWithIdentifier:custom1TableIdentifier];
        cell1.titleLabel.text = self.dict[name][@"Name"];
        cell1.discountLabel.text= self.dict[name][@"Discount"];
        cell1.oldPriceLabel.text= self.dict[name][@"Original_Price"];
        cell1.discountPriceLabel.text= self.dict[name][@"Discount_Price"];
        cell1.imageView.image=[UIImage imageNamed:self.dict[name][@"Logo"]];
        cell=cell1;
    }else if([self.dict[name][@"Type"] isEqual:@"Hot"]){
        static NSString *custom2TableIdentifier = @"NewProductCell";
        NewProductTableViewCell* cell2 = (NewProductTableViewCell *)[tableView dequeueReusableCellWithIdentifier:custom2TableIdentifier];
        cell2.titleLabel.text = self.dict[name][@"Name"];
        cell2.priceLabel.text = self.dict[name][@"Price"];
        cell2.imageView.image=[UIImage imageNamed:self.dict[name][@"Logo"]];
        cell=cell2;
    }else{
        static NSString *custom3TableIdentifier = @"ComingProductCell";
        ComingProductTableViewCell* cell3 = (ComingProductTableViewCell *)[tableView dequeueReusableCellWithIdentifier:custom3TableIdentifier];
        cell3.titleLabel.text = self.dict[name][@"Name"];
        cell3.priceLabel.text = self.dict[name][@"Price"];
        NSLog(@"%@", self.dict[name][@"Price"]);
        cell3.imageView.image=[UIImage imageNamed:self.dict[name][@"Logo"]];
        cell3.dateLabel.text=self.dict[name][@"Release_Date"];
        cell=cell3;
    }
    
//    if (cell == nil)
//    {
//        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SimpleTableCell" owner:self options:nil];
//        cell = [nib objectAtIndex:0];
//    }
    
    
    
    return cell;

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
//    BOOL isVC = [[segue destinationViewController] isKindOfClass:[ViewController class]];
//
//    if(isVC){
        UITableViewCell* cell = (UITableViewCell*)sender;
        ViewController *vc = [segue destinationViewController];
    
        //        vc.imageName = cell.textLabel.text;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        NSMutableArray* names=[[NSMutableArray alloc] init];
    
        for(NSString* i in self.dict){
            [names addObject:i];
        }
        NSString* name=[names objectAtIndex:indexPath.row];
        vc.product= self.dict[name];
    NSDictionary* sendProduct = [[NSDictionary alloc] init];
    sendProduct=self.dict[name];
    NSLog(@"%ld", (long)indexPath.row);
    NSLog(@"%@", name);
    NSLog(@"%@", self.dict);

//    }
    
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
