//
//  ShoppablesToolbar.m
//  screenshot
//
//  Created by Corey Werner on 8/13/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ShoppablesToolbar.h"
#import "screenshot-Swift.h"
#import "Geometry.h"
#import "ShoppableCollectionViewCell.h"

@interface ShoppablesToolbar () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation ShoppablesToolbar
@dynamic delegate;

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _collectionView = ({
            CGFloat p = [Geometry padding];
            CGFloat p2 = p * .5f;
            
            UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
            layout.minimumInteritemSpacing = p;
            layout.minimumLineSpacing = p;
            layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            
            UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
            collectionView.translatesAutoresizingMaskIntoConstraints = NO;
            collectionView.delegate = self;
            collectionView.dataSource = self;
            collectionView.backgroundColor = [UIColor clearColor];
            collectionView.scrollsToTop = NO;
            collectionView.contentInset = UIEdgeInsetsMake(p2, p2, p2, p2);
            collectionView.showsHorizontalScrollIndicator = NO;
            
            [collectionView registerClass:[ShoppableCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
            
            [self addSubview:collectionView];
            [collectionView.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
            [collectionView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
            [collectionView.leftAnchor constraintEqualToAnchor:self.leftAnchor].active = YES;
            [collectionView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
            collectionView;
        });
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.shoppables.count) {
        CGFloat lineSpacing = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).minimumLineSpacing;
        CGFloat spacingsWidth = lineSpacing * (self.shoppables.count - 1);
        CGFloat shoppablesWidth = [self shoppableSize].width * self.shoppables.count;
        CGFloat contentWidth = round(spacingsWidth + shoppablesWidth);
        CGFloat width = self.collectionView.bounds.size.width - self.collectionView.contentInset.left - self.collectionView.contentInset.right;
        
        if (width > contentWidth) {
            UIEdgeInsets insets = self.collectionView.contentInset;
            insets.left = insets.right = (self.collectionView.bounds.size.width - contentWidth) / 2.f;
            self.collectionView.contentInset = insets;
        }
    }
}


#pragma mark - Layout

- (CGSize)shoppableSize {
    CGSize size = CGSizeZero;
    size.height = self.collectionView.bounds.size.height - self.collectionView.contentInset.top - self.collectionView.contentInset.bottom;
    size.width = size.height * .8f;
    return size;
}


#pragma mark - Shoppable

- (void)setScreenshotImage:(UIImage *)screenshotImage {
    if (_screenshotImage != screenshotImage) {
        _screenshotImage = screenshotImage;
        
        if (screenshotImage) {
            [self.collectionView reloadData];
        }
    }
}


#pragma mark - Collection View

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.shoppables.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self shoppableSize];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ShoppableCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.image = [self.shoppables[indexPath.item] croppedWithImage:self.screenshotImage];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate shoppablesToolbar:self didSelectShoppableAtIndex:indexPath.item];
}

- (void)selectFirstItem {
    if ([self.collectionView numberOfItemsInSection:0]) {
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
}

- (NSInteger)selectedShoppableIndex {
    return [self.collectionView.indexPathsForSelectedItems firstObject].item;
}

@end
