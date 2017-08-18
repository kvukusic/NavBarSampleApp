//
//  NavigationBarManager.h
//  NavBarSampleApp
//
//  Created by Kristian Vukušić on 18/08/2017.
//  Copyright © 2017 Test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class NavigationBar;

@interface NavigationBarManager : NSObject

- (instancetype)initWithNavigationBar:(NavigationBar *)navigationBar;

@property (nonatomic, strong, readonly) NavigationBar *navigationBar;
@property (nonatomic, strong) NSArray<UIScrollView *> *scrollViews;

@end
