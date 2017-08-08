//
//  ProductCollectionViewCell.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ProductCollectionViewCell.h"

@interface ProductCollectionViewCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *priceLabel;

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


#pragma mark - Setting

- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleLabel.text = title;
}

- (void)setPrice:(NSString *)price {
    _price = price;
    self.priceLabel.text = price;
}

@end
