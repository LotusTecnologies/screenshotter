//
//  ProductCollectionViewCell.h
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ProductCollectionViewCell;

@protocol ProductCollectionViewCellDelegate <NSObject>
@required

- (void)productCollectionViewCellDidTapFavorite:(ProductCollectionViewCell *)cell;

@end

@interface ProductCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) id<ProductCollectionViewCellDelegate> delegate;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *price;
@property (nonatomic, copy) NSString *imageUrl;

@property (nonatomic, strong, readonly) UIButton *favoriteButton;

+ (CGFloat)labelsHeight;

@end
