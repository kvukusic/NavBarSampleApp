//
//  NavigationBarManager.h
//  NavBarSampleApp
//
//  Created by Kristian Vukušić on 08/08/2017.
//  Copyright © 2017 Test. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NavigationBarManager;

typedef NS_ENUM(NSInteger, NavigationBarState) {
    NavigationBarStateClosed,
    NavigationBarStateContracting,
    NavigationBarStateExpanding,
    NavigationBarStateOpen
};

@protocol NavigationBarManagerDelegate <NSObject>

- (BOOL)navigationBarManager:(NavigationBarManager *)manager shouldUpdateScrollViewInsets:(UIEdgeInsets)insets;
- (void)navigationBarManagerDidUpdateScrollViewInsets:(NavigationBarManager *)manager;
- (void)navigationBarManager:(NavigationBarManager *)manager didChangeStateToState:(NavigationBarState)state;

@end

@interface NavigationBarManager : NSObject <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) id<NavigationBarManagerDelegate> delegate;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

- (instancetype)initWithViewController:(UIViewController *)viewController scrollView:(UIScrollView *)scrollView;

- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidLayoutSubviews;
- (void)viewWillDisappear:(BOOL)animated;
- (void)shouldScrollToTop;
- (void)contract;
- (void)expand;

@end
