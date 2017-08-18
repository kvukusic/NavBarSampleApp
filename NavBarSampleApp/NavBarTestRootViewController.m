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
#import "NavigationBarManager.h"
#import "TabStripBarView.h"

@interface NavBarTestRootViewController ()

@property (nonatomic, strong, readonly) NSMutableArray *childControllers;

@end

@implementation NavBarTestRootViewController {
    NavigationBar *_navigationBar;
    NavigationBarManager *_navigationBarManager;

    NSMutableArray *_childControllers;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationController setNavigationBarHidden:YES animated:NO];

    self.automaticallyAdjustsScrollViewInsets = NO;

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

    _navigationBarManager = [[NavigationBarManager alloc] initWithNavigationBar:_navigationBar];

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

- (void)addViewControllers:(NSArray *)viewControllers {
    if(viewControllers == nil || viewControllers.count == 0){
        return;
    }

    [self.childControllers removeAllObjects];
    [self.childControllers addObjectsFromArray:viewControllers];
    [self reloadTabStripView];

    NSMutableArray<UITableView *> *tableViews = [NSMutableArray array];
    for (UIViewController *controller in self.childControllers) {
        if ([controller respondsToSelector:@selector(tableView)]) {
            UITableView *tableView = [controller performSelector:@selector(tableView)];
            [tableViews addObject:tableView];
        }
    }

    _navigationBarManager.scrollViews = [NSArray arrayWithArray:tableViews];
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

@end
