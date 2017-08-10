//
//  ScreenshotCollectionViewCell.m
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotCollectionViewCell.h"
#import "ScreenshotImage.h"

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
        
        _toolbar = ({
            UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Share"] style:UIBarButtonItemStylePlain target:self action:@selector(shareAction:)];
            UIBarButtonItem *trashButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Trash"] style:UIBarButtonItemStylePlain target:self action:@selector(trashAction:)];
            UIBarButtonItem *flexilbeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            
            UIToolbar *toolbar = [[UIToolbar alloc] init];
            toolbar.translatesAutoresizingMaskIntoConstraints = NO;
            [toolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
            toolbar.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7f];
            toolbar.tintColor = [UIColor whiteColor];
            
            toolbar.items = @[shareButtonItem, flexilbeItem, trashButtonItem];
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

- (void)setScreenshot:(Screenshot *)screenshot {
    _screenshot = screenshot;
    
    if (screenshot) {
        [ScreenshotImage screenshot:screenshot handler:^(UIImage *image, Screenshot *aScreenshot) {
            if (screenshot.objectID == aScreenshot.objectID) {
                self.imageView.image = image;
            }
        }];
    }
}


#pragma mark - Actions

- (void)shareAction:(UIBarButtonItem *)buttonItem {
    [self.delegate screenshotCollectionViewCellDidTapShare:self];
}

- (void)trashAction:(UIBarButtonItem *)buttonItem {
    [self.delegate screenshotCollectionViewCellDidTapTrash:self];
}

@end
