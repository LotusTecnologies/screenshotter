//
//  ProductCollectionViewCell.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ProductCollectionViewCell.h"
#import "screenshot-Swift.h"

@import SDWebImage.UIImageView_WebCache;

@interface ProductCollectionViewCell ()


@end

@implementation ProductCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupProductView];
        [self setupTitleView];
        [self setupPriceLabels];
        [self setupFavoriteButton];
        [self setupSaleImageView];
       
    }
    return self;
}


#pragma mark - Layout

+ (UIFont *)labelFont {
    return [UIFont systemFontOfSize:17.f];
}

+ (CGFloat)labelVerticalPadding {
    return 6.f;
}

+ (NSInteger)titleLabelNumberOfLines {
    return 1;
}

+ (CGFloat)titleLableHeight {
    return ceil([self labelFont].lineHeight + [self labelVerticalPadding]) * [self titleLabelNumberOfLines];
}

+ (CGFloat)priceLabelHeight {
    return ceil([self labelFont].lineHeight + [self labelVerticalPadding]);
}

+ (CGFloat)labelsHeight {
    return [self titleLableHeight] + [self priceLabelHeight];
}


#pragma mark - Labels

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (NSString *)title {
    return self.titleLabel.text;
}

- (void)setPrice:(NSString *)price {
    self.priceLabel.text = price;
}

- (NSString *)price {
    return self.priceLabel.text;
}

- (void)setOriginalPrice:(NSString *)originalPrice {
    if (originalPrice.length) {
        NSDictionary *attributes = @{NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle),
                                     NSStrikethroughColorAttributeName: [UIColor gray6]
                                     };
        self.originalPriceLabel.attributedText = [[NSAttributedString alloc] initWithString:originalPrice attributes:attributes];
        
    } else {
        self.originalPriceLabel.attributedText = nil;
    }
}

- (NSString *)originalPrice {
    return self.originalPriceLabel.text;
}

- (UIEdgeInsets)priceLabelLayoutMargins {
    return UIEdgeInsetsMake(0.f, 0.f, 0.f, -8.f);
}


#pragma mark - Image

- (void)setImageUrl:(NSString *)imageUrl {
    if (_imageUrl != imageUrl) {
        _imageUrl = imageUrl;
        
        [self.productView setImageWithURLString:imageUrl];
    }
}


#pragma mark - Sale

- (void)setIsSale:(BOOL)isSale {
    _isSale = isSale;
    self.saleImageView.hidden = !isSale;
    self.originalPriceLabel.hidden = !isSale;
    self.originalPriceLabelWidthConstraint.active = !isSale;
    self.priceLabel.layoutMargins = isSale ? [self priceLabelLayoutMargins] : UIEdgeInsetsZero;
}


#pragma mark - Actions

- (void)favoriteAction {
    [self.delegate productCollectionViewCellDidTapFavorite:self];
}

@end
