//
//  JXPagerListContainerView.m
//  JXPagerView
//
//  Created by jiaxin on 2018/8/27.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "JXPagerListContainerView.h"
#import "JXPagerMainTableView.h"

@interface JXPagerListContainerView() <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (nonatomic, weak) id<JXPagerListContainerViewDelegate> delegate;
@property (nonatomic, strong) JXPagerListContainerCollectionView *collectionView;
@property (nonatomic, assign) NSInteger selectedIndex;
@end

@implementation JXPagerListContainerView

- (instancetype)initWithDelegate:(id<JXPagerListContainerViewDelegate>)delegate {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _delegate = delegate;
        [self initializeViews];
    }
    return self;
}

- (void)initializeViews {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

    _collectionView = [[JXPagerListContainerCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.pagingEnabled = YES;
    self.collectionView.scrollsToTop = NO;
    self.collectionView.bounces = NO;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    if (@available(iOS 10.0, *)) {
        self.collectionView.prefetchingEnabled = NO;
    }
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self addSubview:self.collectionView];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (!CGRectEqualToRect(self.collectionView.frame, self.bounds)) {
        //因为`self.collectionView.frame = self.bounds`会触发`scrollViewDidScroll`导致selectedIndex无效，所以用临时变量currentIndex记录。
        NSInteger currentIndex = self.selectedIndex;
        [self.collectionView.collectionViewLayout invalidateLayout];
        self.collectionView.frame = self.bounds;
        [self.collectionView reloadData];
        [self.collectionView setContentOffset:CGPointMake(self.collectionView.bounds.size.width*currentIndex, 0) animated:NO];
    }
}

- (void)reloadData {
    [self.collectionView reloadData];
}

- (void)setDefaultSelectedIndex:(NSInteger)defaultSelectedIndex {
    _defaultSelectedIndex = defaultSelectedIndex;
    self.selectedIndex = defaultSelectedIndex;
}

#pragma mark - UICollectionViewDataSource, UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.delegate numberOfRowsInListContainerView:self];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    UIView *listView = [self.delegate listContainerView:self listViewInRow:indexPath.item];
    listView.frame = cell.bounds;
    [cell.contentView addSubview:listView];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate listContainerView:self willDisplayCellAtRow:indexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate listContainerView:self didEndDisplayingCellAtRow:indexPath.item];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return false;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.selectedIndex = self.collectionView.contentOffset.x/self.bounds.size.width;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.mainTableView.scrollEnabled = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.mainTableView.scrollEnabled = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        self.mainTableView.scrollEnabled = YES;
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.mainTableView.scrollEnabled = YES;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.bounds.size;
}

@end


@interface JXPagerListContainerCollectionView ()

@end

@implementation JXPagerListContainerCollectionView

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.gestureDelegate && [self.gestureDelegate respondsToSelector:@selector(pagerListContainerCollectionView:gestureRecognizerShouldBegin:)]) {
        return [self.gestureDelegate pagerListContainerCollectionView:self gestureRecognizerShouldBegin:gestureRecognizer];
    }else {
        if (self.isNestEnabled) {
            if ([gestureRecognizer isMemberOfClass:NSClassFromString(@"UIScrollViewPanGestureRecognizer")]) {
                CGFloat velocityX = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:gestureRecognizer.view].x;
                //x大于0就是往右滑
                if (velocityX > 0) {
                    if (self.contentOffset.x == 0) {
                        return NO;
                    }
                }else if (velocityX < 0) {
                    //x小于0就是往左滑
                    if (self.contentOffset.x + self.bounds.size.width == self.contentSize.width) {
                        return NO;
                    }
                }
            }
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (self.gestureDelegate && [self.gestureDelegate respondsToSelector:@selector(pagerListContainerCollectionView:gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)]) {
        return [self.gestureDelegate pagerListContainerCollectionView:self gestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
    }
    return NO;
}

@end
