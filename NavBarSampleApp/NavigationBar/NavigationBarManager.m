//
//  NavigationBarManager.m
//  NavBarSampleApp
//
//  Created by Kristian Vukušić on 18/08/2017.
//  Copyright © 2017 Test. All rights reserved.
//

#import "NavigationBarManager.h"
#import "NavigationBar.h"

@interface NavigationBarManager () <UIScrollViewDelegate>

@end

@implementation NavigationBarManager {
    NavigationBar *_navigationBar;
}

- (instancetype)initWithNavigationBar:(NavigationBar *)navigationBar
{
    if (self = [super init]) {
        _navigationBar = navigationBar;
    }
    return self;
}

- (NavigationBar *)navigationBar
{
    return _navigationBar;
}

- (void)setScrollViews:(NSArray<UIScrollView *> *)scrollViews
{
    _scrollViews = scrollViews;
}

@end
