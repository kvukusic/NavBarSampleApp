//
//  NavBarTestRootViewController.m
//  NavBarSampleApp
//
//  Created by Kristian Vukušić on 15/08/2017.
//  Copyright © 2017 Test. All rights reserved.
//

#import "NavBarTestRootViewController.h"

#import "NavBarTestViewController.h"
#import "NavigationBar.h"
#import "DelegateSplitter.h"
#import "TabStripBarView.h"

@interface NavBarTestRootViewController () <UIScrollViewDelegate>

@property (nonatomic, strong, readonly) NSMutableArray *childControllers;

@end

@implementation NavBarTestRootViewController {
    NavigationBar *_navigationBar;

    NSMutableArray *_childControllers;
    NSMutableArray *_delegateSplitters;

    NSMutableDictionary<NSValue *, NSNumber *> *_previousOffsets;
    NSMutableDictionary<NSValue *, NSNumber *> *_previousNavigationBarHeights; // TODO mozda se moze maknut
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationController setNavigationBarHidden:YES animated:NO];

    self.automaticallyAdjustsScrollViewInsets = NO;

    _delegateSplitters = [NSMutableArray new];
    _previousOffsets = [NSMutableDictionary new];
    _previousNavigationBarHeights = [NSMutableDictionary new];

    [self.buttonBarView setBackgroundColor:[UIColor clearColor]];
    [self.buttonBarView.selectedBar setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.6]];
    [self.buttonBarView setSelectedBarAlignment:SelectedBarAlignmentCenter];
    [self.buttonBarView setSelectedBarHeight:4];
    [self.buttonBarView setShouldCellsFillAvailableWidth:YES];
    [self.buttonBarView removeFromSuperview];

    _navigationBar = [[NavigationBar alloc] initWithMinimumHeight:64.f maximumHeight:200.f];
    _navigationBar.frame = CGRectMake(0.f, 0.f, self.view.bounds.size.width, _navigationBar.maximumHeight);
    _navigationBar.backgroundColor = [UIColor grayColor];
    _navigationBar.extendedView = self.buttonBarView;
    [self.view addSubview:_navigationBar];

    self.changeCurrentIndexProgressiveBlock = ^void(TabStripBarViewCell *oldCell, TabStripBarViewCell *newCell, CGFloat progressPercentage, BOOL changeCurrentIndex, BOOL animated){
        if (changeCurrentIndex) {
            [oldCell.label setTextColor:[UIColor colorWithWhite:1 alpha:0.6]];
            [newCell.label setTextColor:[UIColor whiteColor]];
        }
    };

    NavBarTestViewController *vc1 = [[NavBarTestViewController alloc] initWithNumberOfItems:20];
    NavBarTestViewController *vc2 = [[NavBarTestViewController alloc] initWithNumberOfItems:5];
    NavBarTestViewController *vc3 = [[NavBarTestViewController alloc] initWithNumberOfItems:30];
    NavBarTestViewController *vc4 = [[NavBarTestViewController alloc] initWithNumberOfItems:100];
    NavBarTestViewController *vc5 = [[NavBarTestViewController alloc] initWithNumberOfItems:4];
    [self addViewControllers:@[vc1, vc3, vc2, vc4, vc5]];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    _navigationBar.frame = CGRectMake(0.f, 0.f, self.view.frame.size.width, _navigationBar.frame.size.height);

    self.containerView.frame = self.view.bounds;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

        for (UIViewController *controller in self.childControllers) {
            if ([controller respondsToSelector:@selector(tableView)]) {
                UITableView *tableView = [controller performSelector:@selector(tableView)];
    
                if (tableView.contentSize.height < tableView.frame.size.height) {
                    UIEdgeInsets contentInset = tableView.contentInset;
                    contentInset.bottom = tableView.frame.size.height - tableView.contentSize.height - _navigationBar.minimumHeight;
                    tableView.contentInset = contentInset;
                    tableView.showsVerticalScrollIndicator = NO;
                } else {
                    UIEdgeInsets contentInset = tableView.contentInset;
                    contentInset.bottom = 0.f;
                    tableView.contentInset = contentInset;
                    tableView.showsVerticalScrollIndicator = YES;
                }
            }
        }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];

    if (scrollView == self.containerView) {
        return;
    }

    [self handleScrollingOfScrollView:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.containerView == scrollView) {
        return;
    }

    if (!decelerate) {
        [self scrollHandlingEndedForScrollView:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.containerView == scrollView) {
        return;
    }

    [self scrollHandlingEndedForScrollView:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [super scrollViewDidEndScrollingAnimation:scrollView];

    if (self.containerView == scrollView) {
        return;
    }

    [self scrollHandlingEndedForScrollView:scrollView];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    if (self.containerView == scrollView) {
        return;
    }

    [self scrollHandlingEndedForScrollView:scrollView];
}

#pragma mark - Private methods

- (void)setPreviousYOffsetOfScrollView:(UIScrollView *)scrollView
{
    NSValue *key = [self dictionaryKeyForScrollView:scrollView];
    _previousOffsets[key] = [NSNumber numberWithDouble:scrollView.contentOffset.y];
}

- (CGFloat)getPreviousYOffsetOfScrollView:(UIScrollView *)scrollView
{
    NSValue *key = [self dictionaryKeyForScrollView:scrollView];
    return _previousOffsets[key].doubleValue;
}

- (void)setPreviousNavigationBarHeight:(CGFloat)height forScrollView:(UIScrollView *)scrollView
{
    NSValue *key = [self dictionaryKeyForScrollView:scrollView];
    _previousNavigationBarHeights[key] = [NSNumber numberWithDouble:height];
}

- (CGFloat)getPreviousNavigationBarHeightForScrollView:(UIScrollView *)scrollView
{
    NSValue *key = [self dictionaryKeyForScrollView:scrollView];
    return _previousNavigationBarHeights[key].doubleValue;
}

- (BOOL)shouldHandleScrollingOfScrollView:(UIScrollView *)scrollView
{
    if (_navigationBar.minimumHeight == _navigationBar.maximumHeight) {
        return NO;
    }

    // if scrolling down when not closed
    CGFloat relativeOffset = MAX(0, scrollView.contentOffset.y + _navigationBar.minimumHeight);

    CGFloat previousYOffset = [self getPreviousYOffsetOfScrollView:scrollView];

    if (!isnan(previousYOffset)) {
        CGFloat deltaY = previousYOffset - scrollView.contentOffset.y;
        if (deltaY > 0.f && relativeOffset > 0) {
            return NO;
        }
    }

    // if scrolling down past top
    if (scrollView.contentOffset.y <= -_navigationBar.maximumHeight &&
        _navigationBar.frame.size.height == _navigationBar.maximumHeight) {
        return NO;
    }

    // if scrolling up past bottom
    if (scrollView.contentOffset.y >= -_navigationBar.minimumHeight &&
        _navigationBar.frame.size.height == _navigationBar.minimumHeight) {
        return NO;
    }

    // if refreshing
    if ([scrollView respondsToSelector:@selector(refreshControl)]) {
        UIRefreshControl *refreshControl = [scrollView performSelector:@selector(refreshControl)];
        if (refreshControl.isRefreshing) {
            return NO;
        }
    }

    return YES;
}

- (void)handleScrollingOfScrollView:(UIScrollView *)scrollView
{
    if (![self shouldHandleScrollingOfScrollView:scrollView]) {
        [self setPreviousYOffsetOfScrollView:scrollView];
        return;
    }

    NSValue *key = [self dictionaryKeyForScrollView:scrollView];
    CGFloat previousYOffset = _previousOffsets[key].doubleValue;

    if (!isnan(previousYOffset)) {
        // calculate the delta
        CGFloat deltaY = previousYOffset - scrollView.contentOffset.y;

        // ignore any scrollOffset beyond the bounds
        CGFloat start = -scrollView.contentInset.top;
        if (previousYOffset < start) {
            deltaY = MIN(0, deltaY - previousYOffset - start);
        }

        CGFloat end = scrollView.contentSize.height - scrollView.bounds.size.height + scrollView.contentInset.bottom;
        if (previousYOffset > end) {
            deltaY = MAX(0, deltaY - previousYOffset + end);
        }

        // update the navigation bar frame
        [self updateNavigationBarHeightWithDelta:deltaY forScrollView:scrollView];
    }

    // update scroll content insets
    [self updateScrollIndicatorInsetsOfScrollView:scrollView];

    // save previous offset
    [self setPreviousYOffsetOfScrollView:scrollView];
}

- (void)scrollHandlingEndedForScrollView:(UIScrollView *)scrollView
{
    // update other table view insets
    for (UIViewController *controller in self.childControllers) {
        if ([controller respondsToSelector:@selector(tableView)]) {
            UITableView *tableView = [controller performSelector:@selector(tableView)];
            if (tableView != scrollView) {
                CGFloat previousNavigationBarHeight = [self getPreviousNavigationBarHeightForScrollView:tableView];
                CGFloat navigationBarHeight = _navigationBar.frame.size.height;
                CGFloat diff = navigationBarHeight - previousNavigationBarHeight;

                id delegate = tableView.delegate;
                tableView.delegate = nil;

                CGPoint contentOffset = tableView.contentOffset;
                contentOffset.y -= diff;
                tableView.contentOffset = contentOffset;
                
                tableView.delegate = delegate;

                // set the new offset as previous offset
                [self setPreviousYOffsetOfScrollView:tableView];

                // set the new navigation bar height as previous height
                [self setPreviousNavigationBarHeight:navigationBarHeight forScrollView:tableView];

                // update the scroll indicator insets
                [self updateScrollIndicatorInsetsOfScrollView:tableView];
            }
        }
    }
}

- (void)updateNavigationBarHeightWithDelta:(CGFloat)delta forScrollView:(UIScrollView *)scrollView
{
    const CGFloat deltaY = delta;
    CGFloat newNavigationBarHeight = _navigationBar.frame.size.height + deltaY;
    newNavigationBarHeight = MAX(MIN(_navigationBar.maximumHeight, newNavigationBarHeight), _navigationBar.minimumHeight);

    CGRect frame = _navigationBar.frame;
    frame.size.height = newNavigationBarHeight;
    _navigationBar.frame = frame;

    [self setPreviousNavigationBarHeight:newNavigationBarHeight forScrollView:scrollView];
}

- (void)updateScrollIndicatorInsetsOfScrollView:(UIScrollView *)scrollView
{
//    CGFloat relativeContentOffset = scrollView.contentInset.top + scrollView.contentOffset.y;
//
//    CGFloat minimumHeight = _navigationBar.minimumHeight;
//    CGFloat maximumHeight = _navigationBar.maximumHeight;
    CGFloat height = _navigationBar.frame.size.height;

    if (scrollView.contentSize.height > 0.f) {
//        CGFloat percentageHeight = (scrollView.bounds.size.height - height - minimumHeight) / (scrollView.contentSize.height);
//
//        CGFloat scrollY = round(MAX(relativeContentOffset*percentageHeight, 0.f) * 2.f) / 2.f;
//        NSLog(@"SCROOLL Y %f", scrollY);

        UIEdgeInsets scrollIndicatorInsets = scrollView.scrollIndicatorInsets;
        scrollIndicatorInsets.top = height/* - scrollY*/;
        scrollView.scrollIndicatorInsets = scrollIndicatorInsets;
    }
}

- (void)addViewControllers:(NSArray *)viewControllers {
    if(viewControllers == nil || viewControllers.count == 0){
        return;
    }

    [self.childControllers removeAllObjects];
    [self.childControllers addObjectsFromArray:viewControllers];
    [self reloadTabStripView];

    [_delegateSplitters removeAllObjects];
    for (UIViewController *controller in self.childControllers) {
        if ([controller respondsToSelector:@selector(tableView)]) {
            UITableView *tableView = [controller performSelector:@selector(tableView)];

            // create delegate proxy
            DelegateSplitter *delegateSplitter = [[DelegateSplitter alloc] initWithFirstDelegate:self secondDelegate:tableView.delegate];
            tableView.delegate = (id<UITableViewDelegate>)delegateSplitter;
            [_delegateSplitters addObject:delegateSplitter];

            // set the initial previous offset values
            NSValue *key = [self dictionaryKeyForScrollView:tableView];
            if (!_previousOffsets[key]) {
                _previousOffsets[key] = [NSNumber numberWithDouble:NAN];
            }

            // set the initial previous navigation bar height values
            [self setPreviousNavigationBarHeight:_navigationBar.frame.size.height forScrollView:tableView];

            // set the initial content inset
            UIEdgeInsets contentInset = tableView.contentInset;
            contentInset.top = _navigationBar.maximumHeight;
            tableView.contentInset = contentInset;

            // set initial scroll indicator inset
            [self updateScrollIndicatorInsetsOfScrollView:tableView];
        }
    }
}

- (NSArray *)childViewControllersForTabStripViewController:(TabStripViewController *)tabStripViewController {
    if (self.childControllers && self.childControllers.count > 0) {
        return [NSArray arrayWithArray:self.childControllers];
    }
    else {
        return @[];
    }
}

- (NSMutableArray *)childControllers {
    if (!_childControllers) {
        _childControllers = [[NSMutableArray alloc] init];
    }
    return _childControllers;
}

- (NSValue *)dictionaryKeyForScrollView:(UIScrollView *)scrollView
{
    return [NSValue valueWithNonretainedObject:scrollView];
}

@end