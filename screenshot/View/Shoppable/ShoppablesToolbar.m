//
//  ShoppablesToolbar.m
//  screenshot
//
//  Created by Corey Werner on 8/13/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ShoppablesToolbar.h"
#import "screenshot-Swift.h"

@class ShoppablesCollectionView;


@implementation ShoppablesToolbar
@dynamic delegate;
@synthesize shoppablesController = _shoppablesController;

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
   
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // This is needed for iOS11
    [self bringSubviewToFront:self.collectionView];
}


#pragma mark - Layout

+ (UIEdgeInsets)preservedCollectionViewContentInset {
    CGFloat p = [Geometry padding];
    CGFloat p2 = p * .5f;
    return UIEdgeInsetsMake(p2, p, p2, p);
}

- (CGSize)shoppableSize {
    CGSize size = CGSizeZero;
    size.height = self.collectionView.bounds.size.height - self.collectionView.contentInset.top - self.collectionView.contentInset.bottom;
    size.width = size.height * .8f;
    return size;
}

- (void)repositionShoppables {
    NSInteger shoppablesCount = [self.shoppablesController shoppables].count;
    
    if (shoppablesCount > 0) {
        CGFloat lineSpacing = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).minimumLineSpacing;
        CGFloat spacingsWidth = lineSpacing * (shoppablesCount - 1);
        CGFloat shoppablesWidth = [self shoppableSize].width * shoppablesCount;
        CGFloat contentWidth = round(spacingsWidth + shoppablesWidth);
        CGFloat width = self.collectionView.bounds.size.width - self.collectionView.contentInset.left - self.collectionView.contentInset.right;
        
        if (width != contentWidth) {
            CGFloat maxHorizontalInset = [[self class] preservedCollectionViewContentInset].left;
            
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
        
        if (shoppablesController && self.screenshotImage) {
            [self.collectionView reloadData];
        }
    }
}

- (void)setScreenshotImage:(UIImage *)screenshotImage {
    if (_screenshotImage != screenshotImage) {
        _screenshotImage = screenshotImage;
        
        if (self.shoppablesController && screenshotImage) {
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
        if (self.contentInset.left == [ShoppablesToolbar preservedCollectionViewContentInset].left) {
            // This generally will happen through state restoration and
            // is needed to prevent undesired animations
            [self.delegate repositionShoppables];
        }
        else {
            [self layoutIfNeeded];
            
            [UIView animateWithDuration:Constants.defaultAnimationDuration animations:^{
                [self.delegate repositionShoppables];
            }];
        }
    }
    else {
        [self.delegate repositionShoppables];
    }
}

@end
