//
//  NavBarTestViewController.m
//  NavBarSampleApp
//
//  Created by Kristian Vukušić on 08/08/2017.
//  Copyright © 2017 Test. All rights reserved.
//

#import "NavBarTestViewController.h"

@interface NavBarTestViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation NavBarTestViewController {
    NSInteger _numOfItems;
}

- (void)commonInit
{
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.refreshControl = [[UIRefreshControl alloc] init];
    [_tableView.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:_tableView];
}

- (instancetype)init
{
    if (self = [super init]) {
        [self commonInit];
        _numOfItems = 100;
    }
    return self;
}

- (instancetype)initWithNumberOfItems:(NSInteger)numOfItems
{
    if (self = [super init]) {
        [self commonInit];
        _numOfItems = numOfItems;
    }
    return self;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    _tableView.frame = self.view.bounds;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.automaticallyAdjustsScrollViewInsets = NO;

//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        _numOfItems = 100;
//        [_tableView reloadData];
//    });

    NSLog(@"VIEW DID LOAD");
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _numOfItems;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"row %ld", indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)refresh:(id)sender
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_tableView.refreshControl endRefreshing];
    });
}

- (NSString *)tabName
{
    return [NSString stringWithFormat:@"%@", @(_numOfItems)];
}

@end
