//
//  NavigationBar.m
//  NavBarSampleApp
//
//  Created by Kristian Vukušić on 09/08/2017.
//  Copyright © 2017 Test. All rights reserved.
//

#import "NavigationBar.h"

@implementation NavigationBar {
    UILabel *_titleLabel;
}

- (void)commonInit
{
    _minimumHeight = 20.0;
    _maximumHeight = 44.0;

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.text = @"Testing some shit";
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_titleLabel];
}

- (instancetype)init
{
    if (self = [super init]) {
        [self commonInit];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
        _maximumHeight = CGRectGetMaxY(frame);
    }

    return self;
}

- (instancetype)initWithHeight:(CGFloat)height
{
    if (self = [super init]) {
        [self commonInit];
        self.minimumHeight = height;
        self.maximumHeight = height;
    }

    return self;
}

- (instancetype)initWithMinimumHeight:(CGFloat)minimumHeight
                        maximumHeight:(CGFloat)maximumHeight
{
    if (self = [super init]) {
        [self commonInit];
        self.minimumHeight = minimumHeight;
        self.maximumHeight = maximumHeight;
    }

    return self;
}

- (void)setMinimumBarHeight:(CGFloat)minimumBarHeight
{
    _minimumHeight = fmax(minimumBarHeight, 0.0);
}

- (void)setMaximumBarHeight:(CGFloat)maximumBarHeight
{
    _maximumHeight = fmax(maximumBarHeight, 0.0);
}

- (void)setExtendedView:(UIView *)extendedView
{
    [_extendedView removeFromSuperview];
    _extendedView = extendedView;
    if (_extendedView) {
        [self addSubview:_extendedView];
    }
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    const CGFloat width = self.frame.size.width;
    const CGFloat height = self.frame.size.height;

    [_titleLabel sizeToFit];
    _titleLabel.frame = CGRectMake(0.f, height - _titleLabel.frame.size.height - 80.f, width, _titleLabel.frame.size.height);

    if (_extendedView) {
        _extendedView.frame = CGRectMake(0,
                                         height - 44,
                                         width,
                                         44);
    }
}

@end
