//
//  NavigationBarManager.m
//  NavBarSampleApp
//
//  Created by Kristian Vukušić on 08/08/2017.
//  Copyright © 2017 Test. All rights reserved.
//

#import "NavigationBarManager.h"
#import "NavigationBarViewController.h"

@implementation NavigationBarManager {
    __weak UIViewController *_viewController;
    __weak UIScrollView *_scrollView;

    NavigationBarViewController *_navigationBarViewController;
    CGFloat _topInset;
    CGFloat _previousYOffset;

    NavigationBarState _currentState;
    NavigationBarState _previousState;
}

- (instancetype)initWithViewController:(UIViewController *)viewController scrollView:(UIScrollView *)scrollView
{
    if (self = [self init]) {
        viewController.extendedLayoutIncludesOpaqueBars = YES;

        _viewController = viewController;
        _scrollView = scrollView;

        UINavigationBar *navigationBar = viewController.navigationController.navigationBar;
        _navigationBarViewController = [[NavigationBarViewController alloc] initWithView:navigationBar];
        _navigationBarViewController.alphaFadeEnabled = YES;

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        panGesture.delegate = self;
        [_scrollView addGestureRecognizer:panGesture];

        __weak __typeof__(self) weakSelf = self;
        _navigationBarViewController.expandedCenter = ^CGPoint(UIView *view) {
            return CGPointMake(CGRectGetMidX(view.bounds),
                               CGRectGetMidY(view.bounds) + [weakSelf statusBarHeight]);
        };

        [self updateContentInsets];
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self expand];
}

- (void)viewDidLayoutSubviews
{
    [self updateContentInsets];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self expand];
}

- (void)shouldScrollToTop
{
    CGFloat top = [self statusBarHeight] + [_navigationBarViewController totalHeight];
    [self updateScrollContentInsetTop:top];
    [_navigationBarViewController snap:NO completion:nil];
}

- (void)contract
{
    [_navigationBarViewController contract];
    _previousYOffset = NAN;
    [self handleScrolling];
}

- (void)expand
{
    [_navigationBarViewController expand];
    _previousYOffset = NAN;
    [self handleScrolling];
}

#pragma mark - Private methods

- (BOOL)isViewControllerVisible
{
    return _viewController.isViewLoaded && _viewController.view.window;
}

- (BOOL)isScrolledToTop
{
    return _scrollView.contentInset.top == -_scrollView.contentOffset.y;
}

- (CGFloat)statusBarHeight
{
    if ([[UIApplication sharedApplication] isStatusBarHidden]) {
        return 0.f;
    }

    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    return MIN(statusBarSize.width, statusBarSize.height);
}

- (BOOL)shouldHandleScrolling
{
    // if scrolling down past top
    if (_scrollView.contentOffset.y <= -_scrollView.contentInset.top && _currentState == NavigationBarStateOpen) {
        return NO;
    }

    // if refreshing
    if (_refreshControl.isRefreshing) {
        return NO;
    }

    CGRect scrollFrame = UIEdgeInsetsInsetRect(_scrollView.bounds, _scrollView.contentInset);
    CGFloat scrollableAmount = _scrollView.contentSize.height - scrollFrame.size.height;
    BOOL scrollViewIsSuffiecentlyLong = scrollableAmount > _navigationBarViewController.totalHeight * 3;

    return [self isViewControllerVisible] && scrollViewIsSuffiecentlyLong;
}

- (void)handleScrolling
{
    NSLog(@"Scrolled %f %f", _scrollView.contentInset.top, -_scrollView.contentOffset.y);

    if (![self shouldHandleScrolling]) {
        return;
    }

    if (!isnan(_previousYOffset)) {
        // 1 - Calculate the delta
        CGFloat deltaY = _previousYOffset - _scrollView.contentOffset.y;

        // 2 - Ignore any scrollOffset beyond the bounds
        CGFloat start = -_topInset;
        if (_previousYOffset < start) {
            deltaY = MIN(0, deltaY - _previousYOffset - start);
        }

        // rounding to resolve a dumb issue with the contentOffset value
        CGFloat end = floor(_scrollView.contentSize.height - _scrollView.bounds.size.height + _scrollView.contentInset.bottom - 0.5);
        if (_previousYOffset > end) {
            deltaY = MAX(0, deltaY - _previousYOffset + end);
        }

        // 3 - Update contracting variable
        if (ABS(deltaY) > FLT_EPSILON) {
            if (deltaY < 0) {
                _currentState = NavigationBarStateContracting;
            } else {
                _currentState = NavigationBarStateExpanding;
            }
        }

        // 4 - Check if contracting state changed, and do stuff if so
        if (_currentState != _previousState) {
            _previousState = _currentState;
        }
        
        // 5 - Update the shyViewController
        [_navigationBarViewController updateYOffsetWithDelta:deltaY];
    }

    // update content insets
    [self updateContentInsets];

    _previousYOffset = _scrollView.contentOffset.y;

    // update the visible state
    NavigationBarState state = _currentState;
    if (CGPointEqualToPoint(_navigationBarViewController.view.center,
                            _navigationBarViewController.expandedCenterValue)) {
        _currentState = NavigationBarStateOpen;
    } else if (CGPointEqualToPoint(_navigationBarViewController.view.center,
                                   _navigationBarViewController.contractedCenterValue)) {
        _currentState = NavigationBarStateClosed;
    }

    if (state != _currentState) {
        [_delegate navigationBarManager:self didChangeStateToState:_currentState];
    }
}

- (void)updateContentInsets
{
    CGFloat navBarBottomY = _navigationBarViewController.view.frame.origin.y + _navigationBarViewController.view.frame.size.height;
    [self updateScrollContentInsetTop:navBarBottomY];
}

- (void)updateScrollContentInsetTop:(CGFloat)top
{
    UIEdgeInsets contentInset = UIEdgeInsetsMake(top,
                                                 _scrollView.contentInset.top,
                                                 _scrollView.contentInset.left,
                                                 _scrollView.contentInset.right);
    if (![_delegate navigationBarManager:self shouldUpdateScrollViewInsets:contentInset]) {
        return;
    }

    if (_viewController.automaticallyAdjustsScrollViewInsets) {
        UIEdgeInsets contentInset = _scrollView.contentInset;
        contentInset.top = top;
        _scrollView.contentInset = contentInset;
    }

    UIEdgeInsets scrollInsets = _scrollView.scrollIndicatorInsets;
    scrollInsets.top = top;
    _scrollView.scrollIndicatorInsets = scrollInsets;
    [_delegate navigationBarManagerDidUpdateScrollViewInsets:self];
}

#pragma mark - Scroll handling

- (void)handlePanGesture:(UIGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        _topInset = _navigationBarViewController.view.frame.size.height + [self statusBarHeight];
        [self handleScrolling];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        [self handleScrolling];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
