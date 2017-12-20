//
//  ShoppablesToolbar.m
//  screenshot
//
//  Created by Corey Werner on 8/13/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ShoppablesToolbar.h"

@class ShoppablesCollectionView;

@interface ShoppablesToolbar () <UICollectionViewDelegate, UICollectionViewDataSource> {
    UIEdgeInsets _preservedCollectionViewContentInset;
    BOOL _needsToSelectFirstShoppable;
}

- (void)repositionShoppables;

@end

@interface ShoppablesCollectionView : UICollectionView

@property (nonatomic, weak) ShoppablesToolbar* delegate;

@end

@implementation ShoppablesToolbar
@dynamic delegate;
@synthesize shoppablesController = _shoppablesController;

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _collectionView = ({
            CGFloat p = [Geometry padding];
            CGFloat p2 = p * .5f;
            
            _preservedCollectionViewContentInset = UIEdgeInsetsMake(p2, p, p2, p);
            
            UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
            layout.minimumInteritemSpacing = p;
            layout.minimumLineSpacing = p;
            layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            
            ShoppablesCollectionView *collectionView = [[ShoppablesCollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
            collectionView.translatesAutoresizingMaskIntoConstraints = NO;
            collectionView.delegate = self;
            collectionView.dataSource = self;
            collectionView.backgroundColor = [UIColor clearColor];
            collectionView.scrollsToTop = NO;
            collectionView.contentInset = _preservedCollectionViewContentInset;
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
    
    // This is needed for iOS11
    [self bringSubviewToFront:self.collectionView];
}


#pragma mark - Layout

- (CGSize)shoppableSize {
    CGSize size = CGSizeZero;
    size.height = self.collectionView.bounds.size.height - self.collectionView.contentInset.top - self.collectionView.contentInset.bottom;
    size.width = size.height * .8f;
    return size;
}

- (void)repositionShoppables {
    if ([self.shoppablesController shoppables].count) {
        CGFloat lineSpacing = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).minimumLineSpacing;
        CGFloat spacingsWidth = lineSpacing * ([self.shoppablesController shoppables].count - 1);
        CGFloat shoppablesWidth = [self shoppableSize].width * [self.shoppablesController shoppables].count;
        CGFloat contentWidth = round(spacingsWidth + shoppablesWidth);
        CGFloat width = self.collectionView.bounds.size.width - self.collectionView.contentInset.left - self.collectionView.contentInset.right;
        
        if (width != contentWidth) {
            CGFloat maxHorizontalInset = _preservedCollectionViewContentInset.left;
            
            UIEdgeInsets insets = self.collectionView.contentInset;
            insets.left = insets.right = MAX(maxHorizontalInset, floor((self.collectionView.bounds.size.width - contentWidth) / 2.f));
            self.collectionView.contentInset = insets;
        }
    }
}


#pragma mark - Shoppable

- (void)setShoppablesController:(ShoppablesController *)shoppablesController {
    if (_shoppablesController != shoppablesController) {
        _shoppablesController = shoppablesController;
        _shoppablesController.collectionView = shoppablesController ? self.collectionView : nil;
    }
}

- (void)setScreenshotImage:(UIImage *)screenshotImage {
    if (_screenshotImage != screenshotImage) {
        _screenshotImage = screenshotImage;
        
        if (screenshotImage) {
            [self.collectionView reloadData];
        }
    }
}

- (void)selectFirstShoppable {
    if ([self.collectionView numberOfItemsInSection:0] > 0) {
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        
    } else {
        _needsToSelectFirstShoppable = YES;
    }
}

- (NSInteger)selectedShoppableIndex {
    return [self.collectionView.indexPathsForSelectedItems firstObject].item;
}


#pragma mark - Collection View

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.shoppablesController shoppables].count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self shoppableSize];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ShoppableCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.image = [[self.shoppablesController shoppables][indexPath.item] croppedWithImage:self.screenshotImage];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([collectionView indexPathsForVisibleItems].count == 0 && [collectionView numberOfItemsInSection:0] > 0 && indexPath.item == 0) {
        if (_needsToSelectFirstShoppable) {
            _needsToSelectFirstShoppable = NO;
            [self selectFirstShoppable];
            
            // selectItemAtIndexPath: should auto select the cell however
            // since the cell isnt visible it wont appear selected until
            // the next layout. Force the selected state.
            cell.selected = YES;
        }
        
        [self.delegate shoppablesToolbarDidChange:self];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate shoppablesToolbar:self didSelectShoppableAtIndex:indexPath.item];
}

@end

@implementation ShoppablesCollectionView
@dynamic delegate;

- (void)setContentSize:(CGSize)contentSize {
    [super setContentSize:contentSize];
    
    if (self.delegate.didViewControllerAppear && [self numberOfItemsInSection:0] > 0) {
        [UIView animateWithDuration:Constants.defaultAnimationDuration animations:^{
            [self.delegate repositionShoppables];
        }];
        
    } else {
        [self.delegate repositionShoppables];
    }
}

@end