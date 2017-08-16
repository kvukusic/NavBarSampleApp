//
//  TabStripBarView.h
//  iphone
//
//  Created by Kristian Vukušić on 25/12/16.
//  Copyright © 2016 SofaScore. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TabStripViewController.h"

typedef NS_ENUM(NSUInteger, PagerScroll) {
    PagerScrollNO,
    PagerScrollYES,
    PagerScrollOnlyIfOutOfScreen
};

typedef NS_ENUM(NSUInteger, SelectedBarAlignment) {
    SelectedBarAlignmentLeft,
    SelectedBarAlignmentCenter,
    SelectedBarAlignmentRight,
    SelectedBarAlignmentProgressive
};

@interface TabStripBarViewCell : UICollectionViewCell

@property (readonly, nonatomic) UILabel * label;

@end

@interface TabStripBarView : UICollectionView

@property (readonly, nonatomic) UIView * selectedBar;
@property (nonatomic) CGFloat selectedBarHeight;
@property (nonatomic) SelectedBarAlignment selectedBarAlignment;
@property (nonatomic) BOOL shouldCellsFillAvailableWidth;
@property UIFont * labelFont;
@property NSUInteger leftRightMargin;

-(void)moveToIndex:(NSUInteger)index animated:(BOOL)animated swipeDirection:(PagerTabStripDirection)swipeDirection pagerScroll:(PagerScroll)pagerScroll;

-(void)moveFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex withProgressPercentage:(CGFloat)progressPercentage pagerScroll:(PagerScroll)pagerScroll;

-(void)updateText:(NSString *)text atIndex:(NSInteger)index;

@end

