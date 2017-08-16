//
//  NavBarTestRootViewController2.m
//  NavBarSampleApp
//
//  Created by Kristian Vukušić on 11/08/2017.
//  Copyright © 2017 Test. All rights reserved.
//

#import "NavBarTestRootViewController2.h"

#import "NavBarTestViewController.h"
#import "NavigationBar.h"
#import "DelegateSplitter.h"
#import "TabStripBarView.h"

@interface NavBarTestRootViewController2 () <UIScrollViewDelegate>

@property (nonatomic, strong, readonly) NSMutableArray *childControllers;

@end

@implementation NavBarTestRootViewController2 {
    NavigationBar *_navigationBar;

    NSMutableArray *_childControllers;
    NSMutableArray *_delegateSplitters;

    NSMutableDictionary<NSValue *, NSNumber *> *_previousOffsets;
    NSMutableDictionary<NSValue *, NSNumber *> *_topInsets;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationController setNavigationBarHidden:YES animated:NO];

    self.automaticallyAdjustsScrollViewInsets = NO;

    _delegateSplitters = [NSMutableArray new];
    _previousOffsets = [NSMutableDictionary new];
    _topInsets = [NSMutableDictionary new];

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

//    for (UIViewController *controller in self.childControllers) {
//        if ([controller respondsToSelector:@selector(tableView)]) {
//            UITableView *tableView = [controller performSelector:@selector(tableView)];
//
//            if (tableView.contentSize.height + tableView.contentInset.top < tableView.frame.size.height) {
//                tableView.contentInset = UIEdgeInsetsMake(tableView.contentInset.top,
//                                                          tableView.contentInset.left,
//                                                          tableView.frame.size.height + tableView.contentInset.top - tableView.contentSize.height,
//                                                          tableView.contentInset.right);
//                tableView.showsVerticalScrollIndicator = NO;
//            } else {
//                tableView.contentInset = UIEdgeInsetsMake(tableView.contentInset.top,
//                                                          tableView.contentInset.left,
//                                                          0.f,
//                                                          tableView.contentInset.right);
//                tableView.showsVerticalScrollIndicator = YES;
//            }
//        }
//    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];

    if (scrollView == self.containerView) {
        return;
    }

    CGFloat topInset = _navigationBar.frame.origin.y + _navigationBar.frame.size.height;
    _topInsets[[self dictionaryKeyForScrollView:scrollView]] = [NSNumber numberWithDouble:topInset];
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

- (BOOL)shouldHandleScrollingOfScrollView:(UIScrollView *)scrollView
{
    if (_navigationBar.minimumHeight == _navigationBar.maximumHeight) {
        return NO;
    }

    // if scrolling down when not closed
    CGFloat relativeOffset = scrollView.contentOffset.y + scrollView.contentInset.top;

    CGFloat previousYOffset = [self getPreviousYOffsetOfScrollView:scrollView];

    if (!isnan(previousYOffset)) {
        CGFloat deltaY = previousYOffset - scrollView.contentOffset.y;
        if (deltaY > 0.f && relativeOffset > 0) {
            return NO;
        }
    }

    // if scrolling down past top
    if (scrollView.contentOffset.y <= -scrollView.contentInset.top && scrollView.contentInset.top == _navigationBar.maximumHeight) {
        return NO;
    }

    // if scrolling up past bottom
    if (scrollView.contentOffset.y >= -scrollView.contentInset.top && scrollView.contentInset.top == _navigationBar.minimumHeight) {
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
        CGFloat start = -_topInsets[key].doubleValue;
        if (previousYOffset < start) {
            deltaY = MIN(0, deltaY - previousYOffset - start);
        }

        CGFloat end = scrollView.contentSize.height - scrollView.bounds.size.height + scrollView.contentInset.bottom;
        if (previousYOffset > end) {
            deltaY = MAX(0, deltaY - previousYOffset + end);
        }

        // update the navigation bar frame
        [self updateNavigationBarHeightWithDelta:deltaY];
    }

    // update content insets
    [self updateContentInsetsOfScrollView:scrollView];

    // save previous offset
    [self setPreviousYOffsetOfScrollView:scrollView];

//    [self scrollHandlingEndedForScrollView:scrollView];
}

- (void)scrollHandlingEndedForScrollView:(UIScrollView *)scrollView
{
    // update other table view insets
    for (UIViewController *controller in self.childControllers) {
        if ([controller respondsToSelector:@selector(tableView)]) {
            UITableView *tableView = [controller performSelector:@selector(tableView)];
            if (tableView != scrollView) {
                CGFloat previousTopInset = tableView.contentInset.top;
                CGFloat previousContentOffset = tableView.contentOffset.y;

                id delegate = tableView.delegate;
                tableView.delegate = nil;

                [self updateContentInsetsOfScrollView:tableView];

                CGPoint contentOffset = tableView.contentOffset;
                contentOffset.y = -tableView.contentInset.top;
                contentOffset.y += previousTopInset + previousContentOffset;
                tableView.contentOffset = contentOffset;

                tableView.delegate = delegate;

                // set the new offset as previous offset
                [self setPreviousYOffsetOfScrollView:tableView];
            }
        }
    }
}

- (void)updateNavigationBarHeightWithDelta:(CGFloat)delta
{
    const CGFloat deltaY = delta;
    CGFloat newNavigationBarHeight = _navigationBar.frame.size.height + deltaY;
    newNavigationBarHeight = MAX(MIN(_navigationBar.maximumHeight, newNavigationBarHeight), _navigationBar.minimumHeight);

    _navigationBar.frame = CGRectMake(_navigationBar.frame.origin.x,
                                      _navigationBar.frame.origin.y,
                                      _navigationBar.frame.size.width,
                                      newNavigationBarHeight);
}

- (void)updateContentInsetsOfScrollView:(UIScrollView *)scrollView
{
    CGFloat navBarBottomY = _navigationBar.frame.origin.y + _navigationBar.frame.size.height;
    UIEdgeInsets contentInsets = scrollView.contentInset;
    contentInsets.top = navBarBottomY;
    scrollView.contentInset = contentInsets;

    [self updateScrollContentInsetTop:navBarBottomY scrollView:scrollView];
}

- (void)updateScrollContentInsetTop:(CGFloat)top scrollView:(UIScrollView *)scrollView
{
    UIEdgeInsets scrollInsets = scrollView.scrollIndicatorInsets;
    scrollInsets.top = top;
    scrollView.scrollIndicatorInsets = scrollInsets;
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

            // set the initial content insets
            [self updateContentInsetsOfScrollView:tableView];
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
