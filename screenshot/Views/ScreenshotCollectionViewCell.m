//
//  ScreenshotCollectionViewCell.m
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotCollectionViewCell.h"

@interface ScreenshotCollectionViewCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIToolbar *toolbar;

@end

@implementation ScreenshotCollectionViewCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = ({
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            [self.contentView addSubview:imageView];
            [imageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
            [imageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
            [imageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
            [imageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            imageView;
        });
        
        _shareButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Share"] style:UIBarButtonItemStylePlain target:nil action:nil];
        
        _trashButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Trash"] style:UIBarButtonItemStylePlain target:nil action:nil];
        
        _toolbar = ({
            UIBarButtonItem *flexilbeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            
            UIToolbar *toolbar = [[UIToolbar alloc] init];
            toolbar.translatesAutoresizingMaskIntoConstraints = NO;
            [toolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
            toolbar.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7f];
            toolbar.tintColor = [UIColor whiteColor];
            
            toolbar.items = @[self.shareButtonItem, flexilbeItem, self.trashButtonItem];
            [self.contentView addSubview:toolbar];
            [toolbar.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
            [toolbar.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
            [toolbar.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            toolbar;
        });
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.image = nil;
}


#pragma mark -

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
}

- (UIImage *)image {
    return self.imageView.image;
}

@end
