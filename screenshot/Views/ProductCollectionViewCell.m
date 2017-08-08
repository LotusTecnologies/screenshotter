//
//  ProductCollectionViewCell.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ProductCollectionViewCell.h"
#import "FavoriteButton.h"

@interface ProductCollectionViewCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *priceLabel;
@property (nonatomic, strong) FavoriteButton *favoriteButton;

@end

@implementation ProductCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = ({
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            imageView.backgroundColor = [UIColor redColor];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [self.contentView addSubview:imageView];
            [imageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
            [imageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
            [imageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            [imageView.heightAnchor constraintEqualToAnchor:imageView.widthAnchor].active = YES;
            imageView;
        });
        
        _titleLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.backgroundColor = [UIColor yellowColor];
            label.numberOfLines = 2;
            label.textAlignment = NSTextAlignmentCenter;
            [self.contentView addSubview:label];
            
            [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:[[self class] titleLableHeight]].active = YES;
            
            [label.topAnchor constraintEqualToAnchor:self.imageView.bottomAnchor].active = YES;
            [label.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
            [label.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            label;
        });
        
        _priceLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.backgroundColor = [UIColor orangeColor];
            label.textAlignment = NSTextAlignmentCenter;
            [self.contentView addSubview:label];

            [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:[[self class] priceLabelHeight]].active = YES;
            
            [label.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor].active = YES;
            [label.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
            [label.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            [label.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor].active = YES;
            label;
        });
        
        _favoriteButton = ({
            FavoriteButton *button = [FavoriteButton buttonWithType:UIButtonTypeCustom];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            [self.contentView addSubview:button];
            [button.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
            [button.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            button;
        });
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.imageView.image = nil;
    self.titleLabel.text = nil;
    self.priceLabel.text = nil;
}


#pragma mark - Layout

+ (CGFloat)titleLableHeight {
    return 80.f;
}

+ (CGFloat)priceLabelHeight {
    return 40.f;
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

@end
