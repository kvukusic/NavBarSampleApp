//
//  NavBarTestViewController.h
//  NavBarSampleApp
//
//  Created by Kristian Vukušić on 08/08/2017.
//  Copyright © 2017 Test. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TabStripViewController.h"

@interface NavBarTestViewController : UIViewController <TabStripChildItem>

@property (nonatomic, strong) UITableView *tableView;

- (instancetype)initWithNumberOfItems:(NSInteger)numOfItems;

@end
