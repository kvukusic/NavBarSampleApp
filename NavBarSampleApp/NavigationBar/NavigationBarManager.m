//
//  NavigationBarManager.m
//  NavBarSampleApp
//
//  Created by Kristian Vukušić on 18/08/2017.
//  Copyright © 2017 Test. All rights reserved.
//

#import "NavigationBarManager.h"

#import "NavigationBar.h"
#import "DelegateSplitter.h"

static void * const kContentSizeChangeContext = (void*)&kContentSizeChangeContext;
static NSString * const kContentSizePropertyName = @"contentSize";

@interface NavigationBarManager () <UIScrollViewDelegate>

@end

@implementation NavigationBarManager {
    NavigationBar *_navigationBar;

    NSMutableArray *_delegateSplitters;

    NSMutableDictionary<NSValue *, NSNumber *> *_previousOffsets;
    NSMutableDictionary<NSValue *, NSNumber *> *_previousNavigationBarHeights;
}

- (instancetype)initWithNavigationBar:(NavigationBar *)navigationBar
{
    if (self = [super init]) {
        _navigationBar = navigationBar;

        _delegateSplitters = [NSMutableArray array];
        _previousOffsets = [NSMutableDictionary dictionary];
        _previousNavigationBarHeights = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NavigationBar *)navigationBar
{
    return _navigationBar;
}

- (void)setScrollViews:(NSArray<UIScrollView *> *)scrollViews
{
    _scrollViews = [NSArray arrayWithArray:scrollViews];

    [_delegateSplitters removeAllObjects];
    for (UIScrollView *tableView in _scrollViews) {

        // create delegate proxy
        DelegateSplitter *delegateSplitter = [[DelegateSplitter alloc] initWithFirstDelegate:self secondDelegate:tableView.delegate];
        tableView.delegate = (id<UIScrollViewDelegate>)delegateSplitter;
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

        // the content size height is probably zero here
        // this is done to allow scroll offset synchronization for table views with smaller
        // content sizes
        [self handleContentSizeChangeOfScrollView:tableView];

        // TODO check if tableview already observed

        // add contentSize observer
        [tableView addObserver:self
                    forKeyPath:kContentSizePropertyName
                       options:0
                       context:kContentSizeChangeContext];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self handleScrollingOfScrollView:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self scrollHandlingEndedForScrollView:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollHandlingEndedForScrollView:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self scrollHandlingEndedForScrollView:scrollView];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    [self scrollHandlingEndedForScrollView:scrollView];
}

#pragma mark - Private methods

- (NSValue *)dictionaryKeyForScrollView:(UIScrollView *)scrollView
{
    return [NSValue valueWithNonretainedObject:scrollView];
}

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
    CGFloat previousYOffset = [self getPreviousYOffsetOfScrollView:scrollView];
    if (!isnan(previousYOffset)) {
        CGFloat relativeOffset = MAX(0, scrollView.contentOffset.y + _navigationBar.minimumHeight);
        CGFloat deltaY = previousYOffset - scrollView.contentOffset.y;
        if (deltaY > 0.f && relativeOffset > 0) {
            return NO; // TODO problem when relativeOffset > 0 but navbar height > minimum navbar height
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

        // delta correction for fast scrolling upwards when navigation bar is open
        if (previousYOffset < -_navigationBar.maximumHeight) {
            deltaY = MIN(0, deltaY - previousYOffset - _navigationBar.maximumHeight);
        }

        // delta correction when fast scrolling downwards when navigation bar is closed
        if (previousYOffset < 0.f && previousYOffset > -_navigationBar.minimumHeight) {
            if (deltaY > 0.f) {
                deltaY = MIN(deltaY, deltaY - previousYOffset - _navigationBar.minimumHeight);
            }
        }

        // delta correction when scrolling below bottom
        CGFloat end = scrollView.contentSize.height - scrollView.bounds.size.height + scrollView.contentInset.bottom;
        if (scrollView.contentSize.height > scrollView.bounds.size.height && previousYOffset > end) {
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
    for (UIScrollView *tableView in _scrollViews) {
        if (tableView != scrollView) {

            // calculate needed values
            CGFloat previousNavigationBarHeight = [self getPreviousNavigationBarHeightForScrollView:tableView];
            CGFloat navigationBarHeight = _navigationBar.frame.size.height;
            CGFloat diff = navigationBarHeight - previousNavigationBarHeight;

            // save and nil delegate
            id delegate = tableView.delegate;
            tableView.delegate = nil;

            CGPoint contentOffset = tableView.contentOffset;
            contentOffset.y -= diff;

            // add correction for refresh control if refreshing
            if (tableView.refreshControl.isRefreshing) {
                // add correction only if refresh control is visible (above content)
                if (tableView.contentOffset.y < -_navigationBar.maximumHeight) {
                    CGFloat diff = tableView.contentOffset.y + _navigationBar.maximumHeight;
                    contentOffset.y -= diff;
                }
            }

            // set new content offset
            tableView.contentOffset = contentOffset;

            // restore delegate
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
    CGFloat navigationBarHeight = _navigationBar.frame.size.height;
    CGFloat relativeContentOffset = MIN(_navigationBar.maximumHeight + scrollView.contentOffset.y,
                                        _navigationBar.maximumHeight - _navigationBar.minimumHeight);

    if (scrollView.contentSize.height > 0.f) {

        // calculate the scroll indicator correction by iterating N times and recalculating the correction
        // with the applied correction from the previous iteration
        NSInteger i = 0;
        CGFloat scrollIndicatorCorrection = 0.f;
        const NSInteger maxIterations = 10;
        while (i++ < maxIterations) {
            CGFloat scrollableContent = scrollView.contentInset.top + scrollView.contentSize.height + scrollView.contentInset.bottom;
            CGFloat visibleContent = scrollView.bounds.size.height - navigationBarHeight + scrollIndicatorCorrection;
            CGFloat percentageHeight = visibleContent / scrollableContent;
            CGFloat temp = round(MAX(relativeContentOffset * percentageHeight, 0.f) * 2.f) / 2.f;
            if (temp != scrollIndicatorCorrection) {
                scrollIndicatorCorrection = temp;
            } else {
                break;
            }
        }

        UIEdgeInsets scrollIndicatorInsets = scrollView.scrollIndicatorInsets;
        scrollIndicatorInsets.top = navigationBarHeight - scrollIndicatorCorrection;
        scrollView.scrollIndicatorInsets = scrollIndicatorInsets;
    }
}

- (void)handleContentSizeChangeOfScrollView:(UIScrollView *)scrollView
{
    if (scrollView.contentSize.height < scrollView.frame.size.height) {
        UIEdgeInsets contentInset = scrollView.contentInset;
        contentInset.bottom = scrollView.frame.size.height - scrollView.contentSize.height - _navigationBar.minimumHeight;
        scrollView.contentInset = contentInset;

        if (scrollView.contentSize.height > scrollView.frame.size.height - scrollView.contentInset.top) {
            // if content doesn't fit available space then show scroll indicator
            scrollView.showsVerticalScrollIndicator = YES;
        } else {
            // otherwise there is not need to show scroll indicator
            scrollView.showsVerticalScrollIndicator = NO;
        }
    } else {
        UIEdgeInsets contentInset = scrollView.contentInset;
        contentInset.bottom = 0.f;
        scrollView.contentInset = contentInset;
        scrollView.showsVerticalScrollIndicator = YES;
    }
    
    [self updateScrollIndicatorInsetsOfScrollView:scrollView];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == kContentSizeChangeContext) {
        UITableView *tableView = (UITableView *)object;
        [self handleContentSizeChangeOfScrollView:tableView];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - dealloc

- (void)dealloc
{
    for (UIScrollView *scrollView in _scrollViews) {
        // remove content size observer
        [scrollView removeObserver:self
                        forKeyPath:kContentSizePropertyName
                           context:kContentSizeChangeContext];
    }
}

@end
