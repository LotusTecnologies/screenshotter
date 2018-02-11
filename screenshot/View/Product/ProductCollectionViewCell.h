//
//  ProductCollectionViewCell.h
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ProductCollectionViewCell, EmbossedView, FavoriteButton;

@protocol ProductCollectionViewCellDelegate <NSObject>
@required

- (void)productCollectionViewCellDidTapFavorite:(ProductCollectionViewCell *)cell;

@end

@interface ProductCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) id<ProductCollectionViewCellDelegate> delegate;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *price;
@property (nonatomic, copy) NSString *originalPrice;
@property (nonatomic, copy) NSString *imageUrl;

@property (nonatomic) BOOL isSale;

+ (CGFloat)labelsHeight;


@property (nonatomic, strong) EmbossedView *productView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *priceLabel;
@property (nonatomic, strong) UILabel *originalPriceLabel;
@property (nonatomic, strong) NSLayoutConstraint *originalPriceLabelWidthConstraint;
@property (nonatomic, strong) FavoriteButton *favoriteButton;
@property (nonatomic, strong) UIImageView *saleImageView;



+ (UIFont *)labelFont;

+ (CGFloat)labelVerticalPadding;

+ (NSInteger)titleLabelNumberOfLines ;

+ (CGFloat)titleLableHeight ;

+ (CGFloat)priceLabelHeight ;
- (UIEdgeInsets)priceLabelLayoutMargins;

@end
