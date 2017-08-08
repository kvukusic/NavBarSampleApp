//
//  NavBarTestViewController.m
//  NavBarSampleApp
//
//  Created by Kristian Vukušić on 08/08/2017.
//  Copyright © 2017 Test. All rights reserved.
//

#import "NavBarTestViewController.h"

#import "NavigationBarManager.h"
#import "NavigationBarViewController.h"

@interface NavBarTestViewController () <UITableViewDataSource, UITableViewDelegate, NavigationBarManagerDelegate>

@end

@implementation NavBarTestViewController {
    UITableView *_tableView;
    NavigationBarManager *_navbarManager;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:_tableView];

    _navbarManager = [[NavigationBarManager alloc] initWithViewController:self scrollView:_tableView];
    _navbarManager.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_navbarManager viewWillAppear:animated];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [_navbarManager viewDidLayoutSubviews];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_navbarManager viewWillDisappear:animated];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    [_navbarManager shouldScrollToTop];
    return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"row %ld", indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)navigationBarManager:(NavigationBarManager *)manager didChangeStateToState:(NavigationBarState)state
{

}

- (void)navigationBarManagerDidUpdateScrollViewInsets:(NavigationBarManager *)manager
{

}

- (BOOL)navigationBarManager:(NavigationBarManager *)manager shouldUpdateScrollViewInsets:(UIEdgeInsets)insets
{
    return YES;
}

@end
