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

@property (nonatomic, strong) EmbossedView *productView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *priceLabel;
@property (nonatomic, strong) UILabel *originalPriceLabel;
@property (nonatomic, strong) NSLayoutConstraint *originalPriceLabelWidthConstraint;
@property (nonatomic, strong) FavoriteButton *favoriteButton;
@property (nonatomic, strong) UIImageView *saleImageView;

@end

@implementation ProductCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _productView = ({
            CGRect pathRect = CGRectMake(0.f, 0.f, self.bounds.size.width, self.bounds.size.width);
            
            EmbossedView *productView = [[EmbossedView alloc] init];
            productView.translatesAutoresizingMaskIntoConstraints = NO;
            productView.placeholderImage = [UIImage imageNamed:@"DefaultProduct"];
            productView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:[_Shadow pathRect:pathRect] cornerRadius:[Geometry defaultCornerRadius]].CGPath;
            [self.contentView addSubview:productView];
            [productView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
            [productView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
            [productView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            [productView.heightAnchor constraintEqualToAnchor:productView.widthAnchor].active = YES;
            productView;
        });
        
        _titleLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.numberOfLines = [[self class] titleLabelNumberOfLines];
            label.minimumScaleFactor = .7f;
            label.adjustsFontSizeToFitWidth = YES;
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [[self class] labelFont];
            [self.contentView addSubview:label];
            
            [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:[[self class] titleLableHeight]].active = YES;
            
            [label.topAnchor constraintEqualToAnchor:self.productView.bottomAnchor].active = YES;
            [label.leadingAnchor constraintEqualToAnchor:self.productView.leadingAnchor].active = YES;
            [label.trailingAnchor constraintEqualToAnchor:self.productView.trailingAnchor].active = YES;
            label;
        });
        
        UIView *priceContainer = ({
            UIView *view = [[UIView alloc] init];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            [self.contentView addSubview:view];
            [view.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor].active = YES;
            [view.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.titleLabel.leadingAnchor].active = YES;
            [view.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor].active = YES;
            [view.trailingAnchor constraintLessThanOrEqualToAnchor:self.titleLabel.trailingAnchor].active = YES;
            [view.centerXAnchor constraintEqualToAnchor:self.titleLabel.centerXAnchor].active = YES;
            view;
        });
        
        _priceLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [[self class] labelFont];
            label.textColor = [UIColor gray6];
            label.minimumScaleFactor = .7f;
            label.adjustsFontSizeToFitWidth = YES;
            label.layoutMargins = [self priceLabelLayoutMargins];
            [self.contentView addSubview:label];
            [label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            
            [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:[[self class] priceLabelHeight]].active = YES;
            
            [label.topAnchor constraintEqualToAnchor:priceContainer.topAnchor].active = YES;
            [label.leadingAnchor constraintEqualToAnchor:priceContainer.leadingAnchor].active = YES;
            [label.bottomAnchor constraintLessThanOrEqualToAnchor:priceContainer.bottomAnchor].active = YES;
            label;
        });
        
        _originalPriceLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [[self class] labelFont];
            label.textColor = [UIColor gray7];
            label.minimumScaleFactor = .7f;
            label.adjustsFontSizeToFitWidth = YES;
            label.hidden = YES;
            [self.contentView addSubview:label];
            
            [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:[[self class] priceLabelHeight]].active = YES;
            
            [label.topAnchor constraintEqualToAnchor:priceContainer.topAnchor].active = YES;
            [label.leadingAnchor constraintEqualToAnchor:self.priceLabel.layoutMarginsGuide.trailingAnchor].active = YES;
            [label.trailingAnchor constraintEqualToAnchor:priceContainer.trailingAnchor].active = YES;
            [label.bottomAnchor constraintLessThanOrEqualToAnchor:priceContainer.bottomAnchor].active = YES;
            
            self.originalPriceLabelWidthConstraint = [label.widthAnchor constraintEqualToConstant:0.f];
            
            label;
        });
        
        _favoriteButton = ({
            FavoriteButton *button = [FavoriteButton buttonWithType:UIButtonTypeCustom];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            [button addTarget:self action:@selector(favoriteAction) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:button];
            [button.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
            [button.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            button;
        });
        
        _saleImageView = ({
            CGFloat padding = 6.f;
            UIEdgeInsets resizableImageInsets = UIEdgeInsetsMake(0.f, 0.f, 0.f, 4.f);
            
            UIImage *image = [UIImage imageNamed:@"ProductSaleBanner"];
            image = [image resizableImageWithCapInsets:resizableImageInsets];
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            imageView.layoutMargins = UIEdgeInsetsMake(0.f, padding, 0.f, padding + resizableImageInsets.right);
            imageView.hidden = YES;
            [self.productView addSubview:imageView];
            [imageView.leadingAnchor constraintEqualToAnchor:self.productView.leadingAnchor].active = YES;
            [imageView.bottomAnchor constraintEqualToAnchor:self.productView.bottomAnchor constant:-[Geometry defaultCornerRadius]].active = YES;
            
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont boldSystemFontOfSize:10.f];
            label.textAlignment = NSTextAlignmentCenter;
            label.text = @"SALE";
            [imageView addSubview:label];
            [label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            [label.topAnchor constraintEqualToAnchor:imageView.topAnchor].active = YES;
            [label.leadingAnchor constraintEqualToAnchor:imageView.layoutMarginsGuide.leadingAnchor].active = YES;
            [label.bottomAnchor constraintEqualToAnchor:imageView.bottomAnchor].active = YES;
            [label.trailingAnchor constraintEqualToAnchor:imageView.layoutMarginsGuide.trailingAnchor].active = YES;
            
            imageView;
        });
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
