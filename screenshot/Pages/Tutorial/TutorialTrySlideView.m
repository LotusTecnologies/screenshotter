//
//  TutorialTrySlideView.m
//  screenshot
//
//  Created by Corey Werner on 8/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialTrySlideView.h"
#import "PermissionsManager.h"
#import "screenshot-Swift.h"

@implementation TutorialTrySlideView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.text = @"Try It Out";
        self.subtitleLabel.text = @"Press the home & power buttons to take a screenshot of this page";
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TutorialTryGraphic"]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:imageView];
        [imageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        [imageView.topAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor].active = YES;
        [imageView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [imageView.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        [imageView.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [imageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
        [imageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = YES;
        
        if ([UIDevice isSimulator]) {
            [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(applicationUserDidTakeScreenshot)]];
        }
    }
    return self;
}

- (void)didEnterSlide {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationUserDidTakeScreenshot) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
}

- (void)willLeaveSlide {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationUserDidTakeScreenshot {
    if (self.window) {
        CGFloat screenScale = [UIScreen mainScreen].scale;
        
        CGRect rect = CGRectZero;
        rect.size.width = self.window.bounds.size.width * screenScale;
        rect.size.height = self.window.bounds.size.height * screenScale;
        
        UIGraphicsBeginImageContext(rect.size);
        [self.window drawViewHierarchyInRect:rect afterScreenUpdates:NO];
        UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [[PermissionsManager sharedPermissionsManager] requestPermissionForType:PermissionTypePhoto response:^(BOOL granted) {
            [[AssetSyncModel sharedInstance] syncTutorialPhotoWithImage:snapshotImage];
            
            if (!granted) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UserDefaultsKeys.tutorialShouldPresentScreenshotPicker];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [self.delegate tutorialTrySlideViewDidComplete:self];
        }];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
