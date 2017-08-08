//
//  NavigationBarViewController.m
//  NavBarSampleApp
//
//  Created by Kristian Vukušić on 08/08/2017.
//  Copyright © 2017 Test. All rights reserved.
//

#import "NavigationBarViewController.h"

@implementation NavigationBarViewController

- (instancetype)initWithView:(UIView *)view
{
    if (self = [super init]) {
        _view = view;
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        _view = [[UIView alloc] initWithFrame:CGRectZero];
        _view.backgroundColor = [UIColor clearColor];
        _view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    }
    return self;
}

- (CGPoint)expandedCenterValue
{
    if (_expandedCenter) {
        return _expandedCenter(_view);
    } else {
        return CGPointZero;
    }
}

- (CGFloat)contractionAmountValue
{
    return _view.bounds.size.height;
}

- (CGPoint)contractedCenterValue
{
    return CGPointMake([self expandedCenterValue].x,
                       [self expandedCenterValue].y - [self contractionAmountValue]);
}

- (BOOL)isContracted
{
    return ABS(_view.center.y - [self contractedCenterValue].y) < FLT_EPSILON;
}

- (BOOL)isExpanded
{
    return ABS(_view.center.y - [self expandedCenterValue].y) < FLT_EPSILON;
}

- (CGFloat)totalHeight
{
    return [self expandedCenterValue].y - [self contractedCenterValue].y;
}

- (void)setAlphaFadeEnabled:(BOOL)alphaFadeEnabled
{
    _alphaFadeEnabled = alphaFadeEnabled;
    if (!alphaFadeEnabled) {
        [self updateSubviewsToAlpha:1.0];
    }
}

- (CGFloat)updateYOffsetWithDelta:(CGFloat)delta
{
    const CGFloat deltaY = delta;
    const CGFloat newYOffset = _view.center.y + deltaY;
    const CGFloat newYCenter = MAX(MIN([self expandedCenterValue].y, newYOffset), [self contractedCenterValue].y);

    _view.center = CGPointMake(_view.center.x, newYCenter);

    if (_alphaFadeEnabled) {
        CGFloat newAlpha = 1.f - ([self expandedCenterValue].y - _view.center.y) * 2.f / [self contractionAmountValue];
        newAlpha = MIN(MAX(FLT_EPSILON, newAlpha), 1.f);

        [self updateSubviewsToAlpha:newAlpha];
    }

    return newYOffset - newYCenter;
}

- (CGFloat)snap:(BOOL)contract completion:(void (^)(void))completion
{
    __block CGFloat deltaY = 0.f;

    [UIView animateWithDuration:0.2 animations:^{
        if (contract) {
            deltaY = [self contract];
        } else {
            deltaY = [self expand];
        }
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];

    return deltaY;
}

- (CGFloat)expand
{
    _view.hidden = NO;

    if (_alphaFadeEnabled) {
        [self updateSubviewsToAlpha:1.f];
        _navSubviews = nil;
    }

    CGFloat amountToMove = [self expandedCenterValue].y - _view.center.y;
    _view.center = [self expandedCenterValue];
    return amountToMove;
}

- (CGFloat)contract
{
    if (_alphaFadeEnabled) {
        [self updateSubviewsToAlpha:0.f];
    }

    CGFloat amountToMove = [self contractedCenterValue].y - _view.center.y;
    _view.center = [self contractedCenterValue];
    return amountToMove;
}

- (void)updateSubviewsToAlpha:(CGFloat)alpha
{
    if (!_navSubviews) {
        NSMutableArray<UIView *> *subviews = [NSMutableArray array];

        for (UIView *subview in _view.subviews) {
            BOOL isBackgroundView = subview == _view.subviews[0];
            BOOL isViewHidden = subview.isHidden || subview.alpha < FLT_EPSILON;

            if (!isBackgroundView && !isViewHidden) {
                [subviews addObject:subview];
            }
        }

        _navSubviews = [NSArray arrayWithArray:subviews];
    }

    for (UIView *subview in _navSubviews) {
        subview.alpha = alpha;
    }
}

@end
