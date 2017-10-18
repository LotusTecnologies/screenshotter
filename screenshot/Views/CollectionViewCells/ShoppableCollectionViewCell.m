//
//  ShoppableCollectionViewCell.m
//  screenshot
//
//  Created by Corey Werner on 8/21/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ShoppableCollectionViewCell.h"
#import "screenshot-Swift.h"

@interface ShoppableCollectionViewCell ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ShoppableCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.layer.borderColor = [self borderColor].CGColor;
        self.layer.borderWidth = 1.f;
        
        _imageView = ({
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [self.contentView addSubview:imageView];
            [imageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
            [imageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
            [imageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
            [imageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            imageView;
        });
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    self.layer.borderColor = selected ? [UIColor crazeRed].CGColor : [self borderColor].CGColor;
}

- (UIColor *)borderColor {
    return [UIColor colorWithWhite:193.f/255.f alpha:1.f];
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
}

- (UIImage *)image {
    return self.imageView.image;
}

@end
