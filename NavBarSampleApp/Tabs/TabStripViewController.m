//
//  TabStripViewController.m
//  iphone
//
//  Created by Kristian Vukušić on 25/12/16.
//  Copyright © 2016 SofaScore. All rights reserved.
//

#import "TabStripViewController.h"
#import "TabStripBarView.h"

@interface TabStripViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) NSArray *pagerTabStripChildViewControllersForScrolling;
@property (nonatomic) NSUInteger currentIndex;

@property (nonatomic) TabStripBarView * buttonBarView;
@property (nonatomic) BOOL shouldUpdateButtonBarView;
@property (nonatomic) NSArray *cachedCellWidths;
@property (nonatomic) BOOL isViewFirstTimeAppearing;
@property (nonatomic) BOOL isViewAppearing;
@property (nonatomic) BOOL isViewRotating;

@end

@implementation TabStripViewController
{
    NSUInteger _lastPageNumber;
    CGFloat _lastContentOffset;
    NSUInteger _pageBeforeRotate;
    CGSize _lastSize;
}

#pragma mark - initializers

- (instancetype)init {
    self = [super init];
    if (self) {
        [self checkShouldAutomaticallyForwardAppearanceMethods];
        [self pagerTabStripViewControllerInit];
    }
    return self;
}

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self){
        [self checkShouldAutomaticallyForwardAppearanceMethods];
        [self pagerTabStripViewControllerInit];
        [self setShouldUpdateButtonBarView:YES];
    }
    return self;
}


-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        [self checkShouldAutomaticallyForwardAppearanceMethods];
        [self pagerTabStripViewControllerInit];
        [self setShouldUpdateButtonBarView:YES];
    }
    return self;
}

-(void)dealloc
{
    self.containerView.delegate = nil;
}

-(void)pagerTabStripViewControllerInit
{
    _currentIndex = 0;
    _delegate = self;
    _dataSource = self;
    _lastContentOffset = 0.0f;
    _isViewFirstTimeAppearing = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!self.containerView){
        self.containerView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
        self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [self.view addSubview:self.containerView];
    }
    self.containerView.clipsToBounds = YES;
    self.containerView.bounces = YES;
    [self.containerView setAlwaysBounceHorizontal:YES];
    [self.containerView setAlwaysBounceVertical:NO];
    self.containerView.scrollsToTop = NO;
    self.containerView.delegate = self;
    self.containerView.showsVerticalScrollIndicator = NO;
    self.containerView.showsHorizontalScrollIndicator = NO;
    self.containerView.pagingEnabled = YES;

    if (self.dataSource){
        _tabStripChildViewControllers = [self.dataSource childViewControllersForTabStripViewController:self];
    }

    if (!self.buttonBarView.superview){
        // If buttonBarView wasn't configured in a XIB or storyboard then it won't have
        // been added to the view so we need to do it programmatically.
        [self.view addSubview:self.buttonBarView];
    }

    if (!self.buttonBarView.delegate){
        self.buttonBarView.delegate = self;
    }
    if (!self.buttonBarView.dataSource){
        self.buttonBarView.dataSource = self;
    }
    self.buttonBarView.labelFont = [UIFont boldSystemFontOfSize:18.0f];
    self.buttonBarView.leftRightMargin = 8;
    self.buttonBarView.scrollsToTop = NO;
    UICollectionViewFlowLayout *flowLayout = (id)self.buttonBarView.collectionViewLayout;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.buttonBarView.showsHorizontalScrollIndicator = NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.buttonBarView layoutIfNeeded];
    self.isViewAppearing = YES;

    if (!self.isViewFirstTimeAppearing && self.currentIndex < self.tabStripChildViewControllers.count) {
        UIViewController *childController = self.tabStripChildViewControllers[self.currentIndex];
        [childController beginAppearanceTransition:YES animated:NO];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _lastSize = self.containerView.bounds.size;
    [self updateIfNeeded];
    self.isViewAppearing = NO;

    if (!self.isViewFirstTimeAppearing && self.currentIndex < self.tabStripChildViewControllers.count) {
        UIViewController *childController = self.tabStripChildViewControllers[self.currentIndex];
        [childController endAppearanceTransition];
    }

    self.isViewFirstTimeAppearing = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (self.currentIndex < self.tabStripChildViewControllers.count) {
        UIViewController *childController = self.tabStripChildViewControllers[self.currentIndex];
        [childController beginAppearanceTransition:NO animated:NO];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    if (self.currentIndex < self.tabStripChildViewControllers.count) {
        UIViewController *childController = self.tabStripChildViewControllers[self.currentIndex];
        [childController endAppearanceTransition];
    }
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    if (self.tabStripChildViewControllers.count == 0) {
        return;
    }

    [self updateIfNeeded];

//    if (self.isViewAppearing || self.isViewRotating) {
        // Force the UICollectionViewFlowLayout to get laid out again with the new size if
        // a) The view is appearing.  This ensures that
        //    collectionView:layout:sizeForItemAtIndexPath: is called for a second time
        //    when the view is shown and when the view *frame(s)* are actually set
        //    (we need the view frame's to have been set to work out the size's and on the
        //    first call to collectionView:layout:sizeForItemAtIndexPath: the view frame(s)
        //    aren't set correctly)
        // b) The view is rotating.  This ensures that
        //    collectionView:layout:sizeForItemAtIndexPath: is called again and can use the views
        //    *new* frame so that the buttonBarView cell's actually get resized correctly
        self.cachedCellWidths = nil; // Clear/invalidate our cache of cell widths
        UICollectionViewFlowLayout *flowLayout = (id)self.buttonBarView.collectionViewLayout;
        [flowLayout invalidateLayout];

        // Ensure the buttonBarView.frame is sized correctly after rotation
        [self.buttonBarView layoutIfNeeded];

        // When the view first appears or is rotated we also need to ensure that the barButtonView's
        // selectedBar is resized and its contentOffset/scroll is set correctly (the selected
        // tab/cell may end up either skewed or off screen after a rotation otherwise)
        [self.buttonBarView moveToIndex:self.currentIndex animated:NO swipeDirection:PagerTabStripDirectionNone pagerScroll:PagerScrollOnlyIfOutOfScreen];
//    }
}

- (void)checkShouldAutomaticallyForwardAppearanceMethods {
    if ([self shouldAutomaticallyForwardAppearanceMethods]) {
        @throw [NSException exceptionWithName:@"Invalid state exception"
                                       reason:@"The method shouldAutomaticallyForwardAppearanceMethods should never be overriden or returning YES when subclassing this controller"
                                     userInfo:nil];
    }
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    // The reason for this is because this controller is a custom scroll view pager
    // that manually calls beginAppearanceTransition and endAppearanceTransition which
    // control the view lifecycle methods
    // If this result would have been YES, then the parent UIViewController calls these viewcycle methods too
    // so we end up with multiple calls of viewWill/DidAppear/Disappear
    return NO;
}

#pragma mark - Properties

- (NSArray *)pagerTabStripChildViewControllersForScrolling
{
    // If a temporary re-ordered version of the view controllers is available return that
    // (i.e. skipIntermediateViewControllers==YES, the user has tapped a tab/cell and
    // we're animating using the re-ordered version)
    // Otherwise just return the normally ordered tabStripChildViewControllers
    return _pagerTabStripChildViewControllersForScrolling ?: self.tabStripChildViewControllers;
}

-(TabStripBarView *)buttonBarView
{
    if (_buttonBarView) return _buttonBarView;

    // If _buttonBarView is nil then it wasn't configured in a XIB or storyboard so
    // this class is being used programatically. We need to initialise the buttonBarView,
    // setup some sensible defaults (which can of course always be re-set in the sub-class),
    // and set an appropriate frame. The buttonBarView gets added to to the view in viewDidLoad:
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    _buttonBarView = [[TabStripBarView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44.0f) collectionViewLayout:flowLayout];
    _buttonBarView.backgroundColor = [UIColor orangeColor];
    _buttonBarView.selectedBar.backgroundColor = [UIColor blackColor];
    _buttonBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    // If a XIB or storyboard hasn't been used we also need to register the cell reuseIdentifier
    // as well otherwise we'll get a crash when the code attempts to dequeue any cell's
    [_buttonBarView registerClass:[TabStripBarViewCell class] forCellWithReuseIdentifier:@"TabStripBarViewCell"];

    return _buttonBarView;
}

- (NSArray *)cachedCellWidths
{
    if (!_cachedCellWidths)
    {
        // First calculate the minimum width required by each cell

        UICollectionViewFlowLayout *flowLayout = (id)self.buttonBarView.collectionViewLayout;
        NSUInteger numberOfCells = self.tabStripChildViewControllers.count;

        NSMutableArray *minimumCellWidths = [[NSMutableArray alloc] init];

        CGFloat collectionViewContentWidth = 0;

        for (UIViewController<TabStripChildItem> *childController in self.tabStripChildViewControllers)
        {
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.font = self.buttonBarView.labelFont;
//            label.text = [childController titleForTabStripViewController:self];
            if ([childController respondsToSelector:@selector(tabName)]) {
                label.text = [childController tabName];
            } else {
                label.text = [childController description];
            }
            CGSize labelSize = [label intrinsicContentSize];

            CGFloat minimumCellWidth = labelSize.width + (self.buttonBarView.leftRightMargin * 2);
            NSNumber *minimumCellWidthValue = [NSNumber numberWithFloat:minimumCellWidth];
            [minimumCellWidths addObject:minimumCellWidthValue];

            collectionViewContentWidth += minimumCellWidth;
        }

        // To get an accurate collectionViewContentWidth account for the spacing between cells
        CGFloat cellSpacingTotal = ((numberOfCells-1) * flowLayout.minimumInteritemSpacing);
        collectionViewContentWidth += cellSpacingTotal;

        CGFloat collectionViewAvailableVisibleWidth = self.buttonBarView.frame.size.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right;

        // Do we need to stretch any of the cell widths to fill the screen width?
        if (!self.buttonBarView.shouldCellsFillAvailableWidth || collectionViewAvailableVisibleWidth < collectionViewContentWidth)
        {
            // The collection view's content width is larger that the visible width available so it needs to scroll
            // OR shouldCellsFillAvailableWidth == NO...
            // No need to stretch any of the cells, we can just use the minimumCellWidths for the cell widths.
            _cachedCellWidths = minimumCellWidths;
        }
        else
        {
            // The collection view's content width is smaller that the visible width available so it won't ever scroll
            // AND shouldCellsFillAvailableWidth == YES so we want to stretch the cells to fill the width.
            // We now need to calculate how much to stretch each tab...

            // In an ideal world the cell's would all have an equal width, however the cell labels vary in length
            // so some of the longer labelled cells might not need to stetch where as the shorter labelled cells do.
            // In order to determine what needs to stretch and what doesn't we have to recurse through suggestedStetchedCellWidth
            // values (the value decreases with each recursive call) until we find a value that works.
            // The first value to try is the largest (for the case where all the cell widths are equal)
            CGFloat stetchedCellWidthIfAllEqual = (collectionViewAvailableVisibleWidth - cellSpacingTotal) / numberOfCells;

            CGFloat generalMiniumCellWidth = [self calculateStretchedCellWidths:minimumCellWidths suggestedStetchedCellWidth:stetchedCellWidthIfAllEqual previousNumberOfLargeCells:0];

            NSMutableArray *stetchedCellWidths = [[NSMutableArray alloc] init];

            for (NSNumber *minimumCellWidthValue in minimumCellWidths)
            {
                CGFloat minimumCellWidth = minimumCellWidthValue.floatValue;
                CGFloat cellWidth = (minimumCellWidth > generalMiniumCellWidth) ? minimumCellWidth : generalMiniumCellWidth;
                NSNumber *cellWidthValue = [NSNumber numberWithFloat:cellWidth];
                [stetchedCellWidths addObject:cellWidthValue];
            }

            _cachedCellWidths = stetchedCellWidths;
        }
    }
    return _cachedCellWidths;
}

- (CGFloat)calculateStretchedCellWidths:(NSArray *)minimumCellWidths suggestedStetchedCellWidth:(CGFloat)suggestedStetchedCellWidth previousNumberOfLargeCells:(NSUInteger)previousNumberOfLargeCells
{
    // Recursively attempt to calculate the stetched cell width

    NSUInteger numberOfLargeCells = 0;
    CGFloat totalWidthOfLargeCells = 0;

    for (NSNumber *minimumCellWidthValue in minimumCellWidths)
    {
        CGFloat minimumCellWidth = minimumCellWidthValue.floatValue;
        if (minimumCellWidth > suggestedStetchedCellWidth) {
            totalWidthOfLargeCells += minimumCellWidth;
            numberOfLargeCells++;
        }
    }

    // Is the suggested width any good?
    if (numberOfLargeCells > previousNumberOfLargeCells)
    {
        // The suggestedStretchedCellWidth is no good :-( ... calculate a new suggested width
        UICollectionViewFlowLayout *flowLayout = (id)self.buttonBarView.collectionViewLayout;
        CGFloat collectionViewAvailableVisibleWidth = self.buttonBarView.frame.size.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right;
        NSUInteger numberOfCells = minimumCellWidths.count;
        CGFloat cellSpacingTotal = ((numberOfCells-1) * flowLayout.minimumInteritemSpacing);

        NSUInteger numberOfSmallCells = numberOfCells - numberOfLargeCells;
        CGFloat newSuggestedStetchedCellWidth =  (collectionViewAvailableVisibleWidth - totalWidthOfLargeCells - cellSpacingTotal) / numberOfSmallCells;

        return [self calculateStretchedCellWidths:minimumCellWidths suggestedStetchedCellWidth:newSuggestedStetchedCellWidth previousNumberOfLargeCells:numberOfLargeCells];
    }

    // The suggestion is good
    return suggestedStetchedCellWidth;
}

#pragma mark - move to another view controller

-(void)moveToViewControllerAtIndex:(NSUInteger)index
{
    [self moveToViewControllerAtIndex:index animated:YES];
}


-(void)moveToViewControllerAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    if (self.viewLoaded && self.shouldUpdateButtonBarView) {
        if (index == self.currentIndex)
            return;

        [self.buttonBarView moveToIndex:index animated:animated swipeDirection:PagerTabStripDirectionNone pagerScroll:PagerScrollYES];
        self.shouldUpdateButtonBarView = NO;

        TabStripBarViewCell *oldCell = (TabStripBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]];
        TabStripBarViewCell *newCell = (TabStripBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
        if (self.changeCurrentIndexProgressiveBlock) {
            self.changeCurrentIndexProgressiveBlock(oldCell, newCell, 1, YES, YES);
        }
    }

    if (!self.isViewLoaded || !self.view.window){
        self.currentIndex = index;
        if (self.isViewLoaded) {
            [self.containerView setContentOffset:CGPointMake([self pageOffsetForChildIndex:self.currentIndex], 0)  animated:NO];
        }
    }
    else{
        if (animated && ABS(self.currentIndex - index) > 1){
            NSMutableArray * tempChildViewControllers = [NSMutableArray arrayWithArray:self.tabStripChildViewControllers];
            UIViewController *currentChildVC = self.tabStripChildViewControllers[self.currentIndex];
            NSUInteger fromIndex = (self.currentIndex < index) ? index - 1 : index + 1;
            UIViewController *fromChildVC = self.tabStripChildViewControllers[fromIndex];
            tempChildViewControllers[self.currentIndex] = fromChildVC;
            tempChildViewControllers[fromIndex] = currentChildVC;
            _pagerTabStripChildViewControllersForScrolling = tempChildViewControllers;
            [self.containerView setContentOffset:CGPointMake([self pageOffsetForChildIndex:fromIndex], 0) animated:NO];
            if (self.navigationController){
                self.navigationController.view.userInteractionEnabled = NO;
            }
            else{
                self.view.userInteractionEnabled = NO;
            }
            [self.containerView setContentOffset:CGPointMake([self pageOffsetForChildIndex:index], 0) animated:YES];
        }
        else{
            [self.containerView setContentOffset:CGPointMake([self pageOffsetForChildIndex:index], 0) animated:animated];
        }

    }
}

-(void)moveToViewController:(UIViewController *)viewController
{
    [self moveToViewControllerAtIndex:[self.tabStripChildViewControllers indexOfObject:viewController]];
}

-(void)moveToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self moveToViewControllerAtIndex:[self.tabStripChildViewControllers indexOfObject:viewController] animated:animated];
}

#pragma mark - PagerTabStripViewControllerDelegate

- (void)tabStripViewController:(TabStripViewController *)tabStripViewController
       indexDidChangeFromIndex:(NSInteger)fromIndex
                       toIndex:(NSInteger)toIndex
{
    NSLog(@"INDEX CHANGED %ld %ld", fromIndex, toIndex);
    // TODO remove
}

- (void)setCurrentIndex:(NSUInteger)currentIndex
{
    NSUInteger oldIndex = _currentIndex;
    NSUInteger newIndex = currentIndex;

    _currentIndex = newIndex;

//    if (oldIndex == 0 && newIndex == 0 && _isViewFirstTimeAppearing) {
//        [self tabStripViewController:self
//             indexDidChangeFromIndex:0 toIndex:0];
//        return;
//    }

    if (oldIndex != newIndex) {
        [self tabStripViewController:self
             indexDidChangeFromIndex:oldIndex
                             toIndex:newIndex];
    }
}

-(void)pagerTabStripViewController:(TabStripViewController *)pagerTabStripViewController
          updateIndicatorFromIndex:(NSInteger)fromIndex
                           toIndex:(NSInteger)toIndex
{
    if (self.shouldUpdateButtonBarView){
        PagerTabStripDirection direction = PagerTabStripDirectionLeft;
        if (toIndex < fromIndex){
            direction = PagerTabStripDirectionRight;
        }
        [self.buttonBarView moveToIndex:toIndex animated:YES swipeDirection:direction pagerScroll:PagerScrollYES];
        if (self.changeCurrentIndexBlock) {
            TabStripBarViewCell *oldCell = (TabStripBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex != fromIndex ? fromIndex : toIndex inSection:0]];
            TabStripBarViewCell *newCell = (TabStripBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]];
            self.changeCurrentIndexBlock(oldCell, newCell, YES);
        }
    }
}

-(void)pagerTabStripViewController:(TabStripViewController *)pagerTabStripViewController
          updateIndicatorFromIndex:(NSInteger)fromIndex
                           toIndex:(NSInteger)toIndex
            withProgressPercentage:(CGFloat)progressPercentage
                   indexWasChanged:(BOOL)indexWasChanged
{
    if (self.shouldUpdateButtonBarView){
        [self.buttonBarView moveFromIndex:fromIndex
                                  toIndex:toIndex
                   withProgressPercentage:progressPercentage pagerScroll:PagerScrollYES];

        if (self.changeCurrentIndexProgressiveBlock) {
            TabStripBarViewCell *oldCell = (TabStripBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex != fromIndex ? fromIndex : toIndex inSection:0]];
            TabStripBarViewCell *newCell = (TabStripBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]];
            self.changeCurrentIndexProgressiveBlock(oldCell, newCell, progressPercentage, indexWasChanged, YES);
        }
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.cachedCellWidths.count > indexPath.row)
    {
        NSNumber *cellWidthValue = self.cachedCellWidths[indexPath.row];
        CGFloat cellWidth = [cellWidthValue floatValue];
        return CGSizeMake(cellWidth, collectionView.frame.size.height);
    }
    return CGSizeZero;
}

#pragma mark - UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //There's nothing to do if we select the current selected tab
    if (indexPath.item == self.currentIndex)
        return;

    [self.buttonBarView moveToIndex:indexPath.item animated:YES swipeDirection:PagerTabStripDirectionNone pagerScroll:PagerScrollYES];
    self.shouldUpdateButtonBarView = NO;

    NSIndexPath *oldCellIndexPath = [NSIndexPath indexPathForItem:self.currentIndex inSection:0];
    NSIndexPath *newCellIndexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:0];

    TabStripBarViewCell *oldCell = (TabStripBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:oldCellIndexPath];
    TabStripBarViewCell *newCell = (TabStripBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:newCellIndexPath];

    if (oldCell == nil) {
        // This means the user manually scrolled away from the current cell which then
        // became unvisible and cannot be retreived using cellForItemAtIndexPath

        // Therefore, we need to manually scroll to the old cell
        CGPoint currentContentOffset = self.buttonBarView.contentOffset;
        [self.buttonBarView scrollToItemAtIndexPath:oldCellIndexPath
                                   atScrollPosition:UICollectionViewScrollPositionNone
                                           animated:NO];

        oldCell = (TabStripBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:oldCellIndexPath];

        if(oldCell == nil) {
            [self.buttonBarView layoutIfNeeded];
            oldCell = (TabStripBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:oldCellIndexPath];
        }

        if(oldCell == nil) {
            [self.buttonBarView reloadData];
            [self.buttonBarView layoutIfNeeded];
            oldCell = (TabStripBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:oldCellIndexPath];
        }

        // And then manually scroll back to the right position
        [self.buttonBarView setContentOffset:currentContentOffset];
    }

    if (self.changeCurrentIndexProgressiveBlock) {
        self.changeCurrentIndexProgressiveBlock(oldCell, newCell, 1, YES, YES);
    }

    [self moveToViewControllerAtIndex:indexPath.item];
}

#pragma mark - UICollectionViewDataSource

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.tabStripChildViewControllers.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TabStripBarViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TabStripBarViewCell" forIndexPath:indexPath];
    NSAssert([cell isKindOfClass:[TabStripBarViewCell class]], @"UICollectionViewCell should be or extend TabStripBarViewCell");
    TabStripBarViewCell * buttonBarCell = cell;
    UIViewController<TabStripChildItem> * childController = self.tabStripChildViewControllers[indexPath.item];

//    [buttonBarCell.label setText:[childController titleForTabStripViewController:self]];
    if ([childController respondsToSelector:@selector(tabName)]) {
        [buttonBarCell.label setText:[childController tabName]];
    } else {
        [buttonBarCell.label setText:[childController description]];
    }

    if (self.buttonBarView.labelFont) {
        buttonBarCell.label.font = self.buttonBarView.labelFont;
    }

    if (self.changeCurrentIndexProgressiveBlock) {
        self.changeCurrentIndexProgressiveBlock(self.currentIndex == indexPath.item ? nil : cell , self.currentIndex == indexPath.item ? cell : nil, 1, YES, NO);
    }

    return buttonBarCell;
}


#pragma mark - PagerTabStripViewControllerDataSource

-(NSArray *)childViewControllersForTabStripViewController:(TabStripViewController *)pagerTabStripViewController
{
    NSAssert(NO, @"Sub-class must implement the TabStripViewControllerDataSource childViewControllersForTabStripViewController: method");
    return nil;
}


#pragma mark - Helpers

-(void)updateIfNeeded
{
    if (!CGSizeEqualToSize(_lastSize, self.containerView.bounds.size)){
        [self updateContent];
    }
}

-(PagerTabStripDirection)scrollDirection
{
    if (self.containerView.contentOffset.x > _lastContentOffset){
        return PagerTabStripDirectionLeft;
    }
    else if (self.containerView.contentOffset.x < _lastContentOffset){
        return PagerTabStripDirectionRight;
    }
    return PagerTabStripDirectionNone;
}

-(BOOL)canMoveToIndex:(NSUInteger)index
{
    return (self.currentIndex != index && self.tabStripChildViewControllers.count > index);
}

-(CGFloat)pageOffsetForChildIndex:(NSUInteger)index
{
    return (index * CGRectGetWidth(self.containerView.bounds));
}

-(CGFloat)offsetForChildIndex:(NSUInteger)index
{
    if (CGRectGetWidth(self.containerView.bounds) > CGRectGetWidth(self.view.bounds)){
        return (index * CGRectGetWidth(self.containerView.bounds) + ((CGRectGetWidth(self.containerView.bounds) - CGRectGetWidth(self.view.bounds)) * 0.5));
    }
    return (index * CGRectGetWidth(self.containerView.bounds));
}

-(CGFloat)offsetForChildViewController:(UIViewController *)viewController
{
    NSInteger index = [self.tabStripChildViewControllers indexOfObject:viewController];
    if (index == NSNotFound){
        @throw [NSException exceptionWithName:NSRangeException reason:nil userInfo:nil];
    }
    return [self offsetForChildIndex:index];
}

-(NSUInteger)pageForContentOffset:(CGFloat)contentOffset
{
    NSInteger result = [self virtualPageForContentOffset:contentOffset];
    return [self pageForVirtualPage:result];
}

-(NSInteger)virtualPageForContentOffset:(CGFloat)contentOffset
{
    NSInteger result = (contentOffset + (1.5f * [self pageWidth])) / [self pageWidth];
    return result - 1;
}

-(NSUInteger)pageForVirtualPage:(NSInteger)virtualPage
{
    if (virtualPage < 0){
        return 0;
    }
    if (virtualPage > self.tabStripChildViewControllers.count - 1){
        return self.tabStripChildViewControllers.count - 1;
    }
    return virtualPage;
}

-(CGFloat)pageWidth
{
    return CGRectGetWidth(self.containerView.bounds);
}

-(CGFloat)scrollPercentage
{
    if ([self scrollDirection] == PagerTabStripDirectionLeft || [self scrollDirection] == PagerTabStripDirectionNone){
        if (fmodf(self.containerView.contentOffset.x, [self pageWidth]) == 0.0) {
            return 1.0;
        }
        return fmodf(self.containerView.contentOffset.x, [self pageWidth]) / [self pageWidth];
    }
    return 1 - fmodf(self.containerView.contentOffset.x >= 0 ? self.containerView.contentOffset.x : [self pageWidth] + self.containerView.contentOffset.x, [self pageWidth]) / [self pageWidth];
}

-(void)updateContent
{
    if (self.tabStripChildViewControllers.count == 0) {
        return;
    }

    if (!CGSizeEqualToSize(_lastSize, self.containerView.bounds.size)){
        if (_lastSize.width != self.containerView.bounds.size.width){
            _lastSize = self.containerView.bounds.size;
            [self.containerView setContentOffset:CGPointMake([self pageOffsetForChildIndex:self.currentIndex], 0) animated:NO];
        }
        else{
            _lastSize = self.containerView.bounds.size;
        }
    }

    NSArray * childViewControllers = self.pagerTabStripChildViewControllersForScrolling;
    self.containerView.contentSize = CGSizeMake(CGRectGetWidth(self.containerView.bounds) * childViewControllers.count, self.containerView.contentSize.height);

    [childViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController * childController = (UIViewController *)obj;
        CGFloat pageOffsetForChild = [self pageOffsetForChildIndex:idx];
        if (fabs(self.containerView.contentOffset.x - pageOffsetForChild) < CGRectGetWidth(self.containerView.bounds)) {
            if (![childController parentViewController]) { // Add child
                [self addChildViewController:childController];
                [childController didMoveToParentViewController:self];

                CGFloat childPosition = [self offsetForChildIndex:idx];
                [childController.view setFrame:CGRectMake(childPosition, 0, MIN(CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.containerView.bounds)), CGRectGetHeight(self.containerView.bounds))];
                childController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

                [childController beginAppearanceTransition:YES animated:NO];
                [self.containerView addSubview:childController.view];
                [childController endAppearanceTransition];
            } else {
                CGFloat childPosition = [self offsetForChildIndex:idx];
                [childController.view setFrame:CGRectMake(childPosition, 0, MIN(CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.containerView.bounds)), CGRectGetHeight(self.containerView.bounds))];
                childController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            }
        } else {
            if ([childController parentViewController]) { // Remove child
                [childController willMoveToParentViewController:nil];
                [childController beginAppearanceTransition:NO animated:NO];
                [childController.view removeFromSuperview];
                [childController endAppearanceTransition];
                [childController removeFromParentViewController];
            }
        }
    }];

    NSUInteger oldCurrentIndex = self.currentIndex;
    NSInteger virtualPage = [self virtualPageForContentOffset:self.containerView.contentOffset.x];
    NSUInteger newCurrentIndex = [self pageForVirtualPage:virtualPage];
    self.currentIndex = newCurrentIndex;
    BOOL changeCurrentIndex = newCurrentIndex != oldCurrentIndex;

    if ([self.delegate respondsToSelector:@selector(pagerTabStripViewController:updateIndicatorFromIndex:toIndex:withProgressPercentage:indexWasChanged:)]){
        CGFloat scrollPercentage = [self scrollPercentage];
        if (scrollPercentage > 0) {
            NSInteger fromIndex = self.currentIndex;
            NSInteger toIndex = self.currentIndex;
            PagerTabStripDirection scrollDirection = [self scrollDirection];
            if (scrollDirection == PagerTabStripDirectionLeft){
                if (virtualPage > self.pagerTabStripChildViewControllersForScrolling.count - 1){
                    fromIndex = self.pagerTabStripChildViewControllersForScrolling.count - 1;
                    toIndex = self.pagerTabStripChildViewControllersForScrolling.count;
                }
                else{
                    if (scrollPercentage >= 0.5f){
                        fromIndex = MAX(toIndex - 1, 0);
                    }
                    else{
                        toIndex = fromIndex + 1;
                    }
                }
            }
            else if (scrollDirection == PagerTabStripDirectionRight) {
                if (virtualPage < 0){
                    fromIndex = 0;
                    toIndex = -1;
                }
                else{
                    if (scrollPercentage > 0.5f){
                        fromIndex = MIN(toIndex + 1, self.pagerTabStripChildViewControllersForScrolling.count - 1);
                    }
                    else{
                        toIndex = fromIndex - 1;
                    }
                }
            }
            [self.delegate pagerTabStripViewController:self updateIndicatorFromIndex:fromIndex toIndex:toIndex withProgressPercentage:( toIndex < 0 || toIndex >= self.pagerTabStripChildViewControllersForScrolling.count ? 0 : scrollPercentage ) indexWasChanged:changeCurrentIndex];
        }
    }
}


#pragma mark - UIScrollViewDelegte

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.containerView == scrollView){
        [self updateContent];
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.shouldUpdateButtonBarView = YES;

    if (self.containerView == scrollView){
        _lastPageNumber = [self pageForContentOffset:scrollView.contentOffset.x];
        _lastContentOffset = scrollView.contentOffset.x;
    }
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (self.containerView == scrollView && _pagerTabStripChildViewControllersForScrolling){
        _pagerTabStripChildViewControllersForScrolling = nil;

        [self updateContent];
    }

    if (self.navigationController){
        self.navigationController.view.userInteractionEnabled = YES;
    }
    else{
        self.view.userInteractionEnabled = YES;
    }

    if (scrollView == self.containerView){
        self.shouldUpdateButtonBarView = YES;
    }
}


-(void)reloadTabStripView
{
    self.cachedCellWidths = nil; // Clear/invalidate our cache of cell widths

    if ([self isViewLoaded]){
        UIViewController *currentViewController = nil;
        if (self.currentIndex < self.tabStripChildViewControllers.count) {
            currentViewController = self.tabStripChildViewControllers[self.currentIndex];
        }

        NSArray *oldControllers = [NSArray arrayWithArray:_tabStripChildViewControllers];
        NSArray *newControllers = self.dataSource ? [self.dataSource childViewControllersForTabStripViewController:self] : @[];

        // Remove previous child controllers with appearance transition
        [oldControllers enumerateObjectsUsingBlock:^(UIViewController *obj, NSUInteger idx, BOOL *stop) {
            if (![newControllers containsObject:obj] && [obj parentViewController]) {
                [obj willMoveToParentViewController:nil];
                [obj beginAppearanceTransition:NO animated:NO];
                [obj.view removeFromSuperview];
                [obj endAppearanceTransition];
                [obj removeFromParentViewController];
            }
        }];

        _tabStripChildViewControllers = newControllers;

        if (self.currentIndex >= self.tabStripChildViewControllers.count){
            self.currentIndex = self.tabStripChildViewControllers.count - 1;
        }

        NSInteger newIndex = [_tabStripChildViewControllers indexOfObject:currentViewController];
        if (newIndex != NSNotFound) {
            self.currentIndex = newIndex;
        }

        [self.buttonBarView reloadData];
        [self.buttonBarView moveToIndex:self.currentIndex animated:NO swipeDirection:PagerTabStripDirectionNone pagerScroll:PagerScrollYES];

        self.containerView.contentSize = CGSizeMake(CGRectGetWidth(self.containerView.bounds) * self.tabStripChildViewControllers.count, self.containerView.contentSize.height);

        [self.containerView setContentOffset:CGPointMake([self pageOffsetForChildIndex:self.currentIndex], 0)  animated:NO];
        [self updateContent];
    }
}

#pragma mark - Orientation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    _pageBeforeRotate = self.currentIndex;
    __typeof__(self) __weak weakSelf = self;
    [coordinator animateAlongsideTransition:nil
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                                     weakSelf.currentIndex = _pageBeforeRotate;
                                     [weakSelf updateIfNeeded];
                                 }];

    self.isViewRotating = YES;
    [coordinator animateAlongsideTransition:nil
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                                     weakSelf.isViewRotating = NO;
                                 }];
}

@end
