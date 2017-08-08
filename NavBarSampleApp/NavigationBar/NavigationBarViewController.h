//
//  NavigationBarViewController.h
//  NavBarSampleApp
//
//  Created by Kristian Vukušić on 08/08/2017.
//  Copyright © 2017 Test. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NavigationBarViewController : NSObject

@property (nonatomic, strong) NSArray<UIView *> *navSubviews;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) CGPoint(^expandedCenter)(UIView *view);
@property (nonatomic, assign) BOOL alphaFadeEnabled;

- (instancetype)initWithView:(UIView *)view;

- (CGPoint)expandedCenterValue;
- (CGFloat)contractionAmountValue;
- (CGPoint)contractedCenterValue;
- (BOOL)isContracted;
- (BOOL)isExpanded;
- (CGFloat)totalHeight;

- (CGFloat)updateYOffsetWithDelta:(CGFloat)delta;
- (CGFloat)snap:(BOOL)contract completion:(void(^)(void))completion;
- (CGFloat)expand;
- (CGFloat)contract;

@end
