//
//  TabStripBarView.m
//  iphone
//
//  Created by Kristian Vukušić on 25/12/16.
//  Copyright © 2016 SofaScore. All rights reserved.
//

#import "TabStripBarView.h"

@interface TabStripBarViewCell()

@property UILabel * label;

@end

@implementation TabStripBarViewCell

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];

    if (!self.label.superview){
        [self.contentView addSubview:self.label];
    }
}

- (UILabel *)label
{
    if (_label) return _label;

    _label = [[UILabel alloc] initWithFrame:self.contentView.bounds];
    _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _label.textAlignment = NSTextAlignmentCenter;
    _label.font = [UIFont systemFontOfSize:14.0f];
    return _label;
}

@end

@interface TabStripBarView ()

@property UIView * selectedBar;
@property NSUInteger selectedOptionIndex;

@end

@implementation TabStripBarView


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initializeButtonBarView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initializeButtonBarView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self initializeButtonBarView];
    }
    return self;
}


-(void)initializeButtonBarView
{
    _selectedOptionIndex = 0;
    _selectedBarHeight = 5;
    if ([self.selectedBar superview] == nil){
        [self addSubview:self.selectedBar];
    }
}


-(void)moveToIndex:(NSUInteger)index animated:(BOOL)animated swipeDirection:(PagerTabStripDirection)swipeDirection pagerScroll:(PagerScroll)pagerScroll
{
    self.selectedOptionIndex = index;
    [self updateSelectedBarPositionWithAnimation:animated swipeDirection:swipeDirection pagerScroll:pagerScroll];
}

-(void)moveFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex withProgressPercentage:(CGFloat)progressPercentage pagerScroll:(PagerScroll)pagerScroll
{
    // First, calculate and set the frame of the 'selectedBar'

    self.selectedOptionIndex = (progressPercentage > 0.5 ) ? toIndex : fromIndex;

    NSInteger numberOfItems = [self.dataSource collectionView:self numberOfItemsInSection:0];
    CGRect fromFrame = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:fromIndex inSection:0]].frame;
    CGRect toFrame;
    if (toIndex < 0 || toIndex > numberOfItems - 1){
        if (toIndex < 0) {
            UICollectionViewLayoutAttributes * cellAtts = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            toFrame = CGRectOffset(cellAtts.frame, -cellAtts.frame.size.width, 0);
        }
        else{
            UICollectionViewLayoutAttributes * cellAtts = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:(numberOfItems - 1) inSection:0]];
            toFrame = CGRectOffset(cellAtts.frame, cellAtts.frame.size.width, 0);
        }
    }
    else{
        toFrame = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:toIndex inSection:0]].frame;
    }
    CGRect targetFrame = fromFrame;
    targetFrame.size.height = self.selectedBar.frame.size.height;
    targetFrame.size.width += (toFrame.size.width - fromFrame.size.width) * progressPercentage;
    targetFrame.origin.x += (toFrame.origin.x - fromFrame.origin.x) * progressPercentage;

    self.selectedBar.frame = CGRectMake(targetFrame.origin.x, self.selectedBar.frame.origin.y, targetFrame.size.width, self.selectedBar.frame.size.height);

    // Next, calculate and set the contentOffset of the UICollectionView
    // (so it scrolls the selectedBar into the appriopriate place given the self.selectedBarAlignment)

    float targetContentOffset = 0;
    // Only bother calculating the contentOffset if there are sufficient tabs that the bar can actually scroll!
    if (self.contentSize.width > self.frame.size.width)
    {
        CGFloat toContentOffset = [self contentOffsetForCellWithFrame:toFrame index:toIndex];
        CGFloat fromContentOffset = [self contentOffsetForCellWithFrame:fromFrame index:fromIndex];

        targetContentOffset = fromContentOffset + ((toContentOffset - fromContentOffset) * progressPercentage);
    }

    // If there is a large difference between the current contentOffset and the contentOffset we're about to set
    // then the change might be visually jarring so animate it.  (This will likely occur if the user manually
    // scrolled the TabStripBarView and then subsequently scrolled the UIPageViewController)
    // Alternatively if the fromIndex and toIndex are the same then this is the last call to this method in the
    // progression so as a precaution always animate this contentOffest change
    BOOL animated = (ABS(self.contentOffset.x - targetContentOffset) > 30) || (fromIndex == toIndex);
    [self setContentOffset:CGPointMake(targetContentOffset, 0) animated:animated];
}

- (void)updateText:(NSString *)text atIndex:(NSInteger)index {
    TabStripBarViewCell *cell = (TabStripBarViewCell *) [self cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    if (cell) {
        cell.label.text = text;
    }
}


-(void)updateSelectedBarPositionWithAnimation:(BOOL)animation swipeDirection:(PagerTabStripDirection __unused)swipeDirection pagerScroll:(PagerScroll)pagerScroll
{
    CGRect selectedBarFrame = self.selectedBar.frame;

    NSIndexPath *selectedCellIndexPath = [NSIndexPath indexPathForItem:self.selectedOptionIndex inSection:0];
    UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:selectedCellIndexPath];
    CGRect selectedCellFrame = attributes.frame;

    [self updateContentOffsetAnimated:animation pagerScroll:pagerScroll toFrame:selectedCellFrame toIndex:selectedCellIndexPath.row];

    selectedBarFrame.size.width = selectedCellFrame.size.width;
    selectedBarFrame.origin.x = selectedCellFrame.origin.x;

    if (animation){
        [UIView animateWithDuration:0.3 animations:^{
            self.selectedBar.frame = selectedBarFrame;
        }];
    }
    else{
        self.selectedBar.frame = selectedBarFrame;
    }
}



#pragma mark - Helpers

- (void)updateContentOffsetAnimated:(BOOL)animated pagerScroll:(PagerScroll)pageScroller toFrame:(CGRect)selectedCellFrame toIndex:(NSUInteger)toIndex
{
    if (pageScroller != PagerScrollNO)
    {
        if (pageScroller == PagerScrollOnlyIfOutOfScreen)
        {
            if  ((selectedCellFrame.origin.x  >= self.contentOffset.x)
                 && (selectedCellFrame.origin.x < (self.contentOffset.x + self.frame.size.width - self.contentInset.left))){
                return;
            }
        }

        CGFloat targetContentOffset = 0;
        // Only bother calculating the contentOffset if there are sufficient tabs that the bar can actually scroll!
        if (self.contentSize.width > self.frame.size.width)
        {
            targetContentOffset = [self contentOffsetForCellWithFrame:selectedCellFrame index:toIndex];
        }

        [self setContentOffset:CGPointMake(targetContentOffset, 0) animated:animated];
    }
}

- (CGFloat)contentOffsetForCellWithFrame:(CGRect)cellFrame index:(NSUInteger)index
{
    UIEdgeInsets sectionInset = ((UICollectionViewFlowLayout *)self.collectionViewLayout).sectionInset;

    CGFloat alignmentOffset = 0;

    switch (self.selectedBarAlignment)
    {
        case SelectedBarAlignmentLeft:
        {
            alignmentOffset = sectionInset.left;
            break;
        }
        case SelectedBarAlignmentRight:
        {
            alignmentOffset = self.frame.size.width - sectionInset.right - cellFrame.size.width;
            break;
        }
        case SelectedBarAlignmentCenter:
        {
            alignmentOffset = (self.frame.size.width - cellFrame.size.width) * 0.5;
            break;
        }
        case SelectedBarAlignmentProgressive:
        {
            CGFloat cellHalfWidth = cellFrame.size.width * 0.5;
            CGFloat leftAlignmentOffest = sectionInset.left + cellHalfWidth;
            CGFloat rightAlignmentOffset = self.frame.size.width - sectionInset.right - cellHalfWidth;
            NSInteger numberOfItems = [self.dataSource collectionView:self numberOfItemsInSection:0];
            CGFloat progress = index / (CGFloat)(numberOfItems - 1);
            alignmentOffset = leftAlignmentOffest + ((rightAlignmentOffset - leftAlignmentOffest) * progress) - cellHalfWidth;
            break;
        }
    }

    CGFloat contentOffset = cellFrame.origin.x - alignmentOffset;

    // Ensure that the contentOffset wouldn't scroll the UICollectioView passed the beginning
    contentOffset = MAX(0, contentOffset);
    // Ensure that the contentOffset wouldn't scroll the UICollectioView passed the end
    contentOffset = MIN(self.contentSize.width - self.frame.size.width, contentOffset);

    return contentOffset;
}

#pragma mark - Properties

- (void)setSelectedBarHeight:(CGFloat)selectedBarHeight
{
    _selectedBarHeight = selectedBarHeight;
    _selectedBar.frame = CGRectMake(_selectedBar.frame.origin.x, self.frame.size.height - _selectedBarHeight, _selectedBar.frame.size.width, _selectedBarHeight);
}

- (UIView *)selectedBar
{
    if (!_selectedBar) {
        _selectedBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - _selectedBarHeight, 0, _selectedBarHeight)];
        _selectedBar.layer.zPosition = 9999;
        _selectedBar.backgroundColor = [UIColor blackColor];
    }
    return _selectedBar;
}

@end
