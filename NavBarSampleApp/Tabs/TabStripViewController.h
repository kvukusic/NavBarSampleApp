//
//  TabStripViewController.h
//  iphone
//
//  Created by Kristian Vukušić on 25/12/16.
//  Copyright © 2016 SofaScore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TabStripViewController;
@class TabStripBarViewCell;
@class TabStripBarViewCell;
@class TabStripBarView;

/**
 The `TabStripChildItem` protocol is adopted by child controllers of TabStripViewController.
 */
@protocol TabStripChildItem <NSObject>

@required

//- (NSString *)titleForTabStripViewController:(TabStripViewController *)pagerTabStripViewController;

- (NSString *)tabName;

@end



typedef NS_ENUM(NSUInteger, PagerTabStripDirection) {
    PagerTabStripDirectionLeft,
    PagerTabStripDirectionRight,
    PagerTabStripDirectionNone
};



@protocol TabStripViewControllerDelegate <NSObject>

@optional

- (void)tabStripViewController:(TabStripViewController *)tabStripViewController
       indexDidChangeFromIndex:(NSInteger)fromIndex
                       toIndex:(NSInteger)toIndex;

-(void)pagerTabStripViewController:(TabStripViewController *)pagerTabStripViewController
          updateIndicatorFromIndex:(NSInteger)fromIndex
                           toIndex:(NSInteger)toIndex;

-(void)pagerTabStripViewController:(TabStripViewController *)pagerTabStripViewController
          updateIndicatorFromIndex:(NSInteger)fromIndex
                           toIndex:(NSInteger)toIndex
            withProgressPercentage:(CGFloat)progressPercentage
                   indexWasChanged:(BOOL)indexWasChanged;

@end


@protocol TabStripViewControllerDataSource <NSObject>

@required

-(NSArray *)childViewControllersForTabStripViewController:(TabStripViewController *)tabStripViewController;

@end



@interface TabStripViewController : UIViewController <TabStripViewControllerDelegate, TabStripViewControllerDataSource, UIScrollViewDelegate>

@property (readonly) NSArray * tabStripChildViewControllers;
@property (nonatomic, retain) UIScrollView * containerView;
@property (nonatomic, assign) id<TabStripViewControllerDelegate> delegate;
@property (nonatomic, assign) id<TabStripViewControllerDataSource> dataSource;

@property (readonly) NSUInteger currentIndex;

-(void)moveToViewControllerAtIndex:(NSUInteger)index;
-(void)moveToViewControllerAtIndex:(NSUInteger)index animated:(BOOL)animated;
-(void)moveToViewController:(UIViewController *)viewController;
-(void)moveToViewController:(UIViewController *)viewController animated:(BOOL)animated;
-(void)reloadTabStripView;

@property (copy) void (^changeCurrentIndexProgressiveBlock)(TabStripBarViewCell* oldCell, TabStripBarViewCell *newCell, CGFloat progressPercentage, BOOL indexWasChanged, BOOL fromCellRowAtIndex);
@property (copy) void (^changeCurrentIndexBlock)(TabStripBarViewCell* oldCell, TabStripBarViewCell *newCell, BOOL animated);

@property (readonly, nonatomic) TabStripBarView * buttonBarView;

@end
