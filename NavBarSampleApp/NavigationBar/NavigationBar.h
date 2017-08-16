//
//  NavigationBar.h
//  NavBarSampleApp
//
//  Created by Kristian Vukušić on 09/08/2017.
//  Copyright © 2017 Test. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, NavigationBarStyle) {
    NavigationBarStyleDark,
    NavigationBarStyleLight
};

@interface NavigationBar : UIView

@property (nonatomic, assign) CGFloat minimumHeight;
@property (nonatomic, assign) CGFloat maximumHeight;
@property (nonatomic, strong) UIView *extendedView;

- (instancetype)initWithHeight:(CGFloat)height;
- (instancetype)initWithMinimumHeight:(CGFloat)minimumHeight
                        maximumHeight:(CGFloat)maximumHeight;

@end
