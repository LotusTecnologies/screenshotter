//
//  InfoCollectionViewCell.m
//  screenshot
//
//  Created by Corey Werner on 9/11/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "InfoCollectionViewCell.h"
#import "NotifySizeChangeView.h"
#import "Geometry.h"
#import "screenshot-Swift.h"

@interface InfoCollectionViewCell ()

@property (nonatomic, strong) UIView *mainView;
@property (nonatomic, strong) UIView *shadowView;
@property (nonatomic, strong) UIView *detailsView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;

@end

@implementation InfoCollectionViewCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.layoutMargins = UIEdgeInsetsZero;
        
        _mainView = ({
            UIView *view = [[UIView alloc] init];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            view.layer.cornerRadius = 12.f;
            view.layer.masksToBounds = YES;
            [self.contentView addSubview:view];
            [view.topAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.topAnchor].active = YES;
            [view.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor].active = YES;
            [view.bottomAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.bottomAnchor].active = YES;
            [view.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
            view;
        });
        
        _shadowView = ({
            UIView *view = [[UIView alloc] init];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            view.layer.shadowColor = [UIColor blackColor].CGColor;
            view.layer.shadowOffset = CGSizeMake(0.f, 2.f);
            view.layer.shadowRadius = 2.f;
            view.layer.shadowOpacity = .3f;
            [self.contentView insertSubview:view belowSubview:self.mainView];
            [view.topAnchor constraintEqualToAnchor:self.mainView.topAnchor].active = YES;
            [view.leadingAnchor constraintEqualToAnchor:self.mainView.leadingAnchor].active = YES;
            [view.bottomAnchor constraintEqualToAnchor:self.mainView.bottomAnchor].active = YES;
            [view.trailingAnchor constraintEqualToAnchor:self.mainView.trailingAnchor].active = YES;
            view;
        });
        
        NotifySizeChangeView *widthChangeView = [[NotifySizeChangeView alloc] init];
        widthChangeView.translatesAutoresizingMaskIntoConstraints = NO;
        widthChangeView.notification = ^(CGSize size) {
            self.shadowView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.mainView.bounds cornerRadius:self.mainView.layer.cornerRadius].CGPath;
        };
        [self.contentView addSubview:widthChangeView];
        [widthChangeView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [widthChangeView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
    }
    return self;
}


#pragma mark - Layout

- (void)setType:(InfoCollectionViewCellType)type {
    _type = type;
    
    [self removeViews];
    
    switch (type) {
        case InfoCollectionViewCellTypeNoShoppables:
            [self setupDetailsView];
            break;
            
        case InfoCollectionViewCellTypeNoFashion:
            [self setupDetailsView];
            [self setupButtonsView];
            break;
    }
}

- (void)setupDetailsView {
    CGFloat p = [Geometry padding];
    CGFloat p2 = p * .7f;
    
    _detailsView = ({
        UIView *view = [[UIView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.backgroundColor = [UIColor whiteColor];
        view.layoutMargins = UIEdgeInsetsMake(p, p2, p, p2);
        [self.mainView addSubview:view];
        [view.topAnchor constraintEqualToAnchor:self.mainView.topAnchor].active = YES;
        [view.leadingAnchor constraintEqualToAnchor:self.mainView.leadingAnchor].active = YES;
        
        if (self.type == InfoCollectionViewCellTypeNoShoppables) {
            [view.bottomAnchor constraintEqualToAnchor:self.mainView.bottomAnchor].active = YES;
            
        } else if (self.type == InfoCollectionViewCellTypeNoFashion) {
            [view.bottomAnchor constraintLessThanOrEqualToAnchor:self.mainView.bottomAnchor].active = YES;
        }
        
        [view.trailingAnchor constraintEqualToAnchor:self.mainView.trailingAnchor].active = YES;
        view;
    });

    _imageView = ({
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"InfoCellCircledI"]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, 0.f, -p2);
        [self.detailsView addSubview:imageView];
        [imageView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [imageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [imageView.topAnchor constraintEqualToAnchor:self.detailsView.layoutMarginsGuide.topAnchor].active = YES;
        [imageView.leadingAnchor constraintEqualToAnchor:self.detailsView.layoutMarginsGuide.leadingAnchor].active = YES;
        [imageView.bottomAnchor constraintLessThanOrEqualToAnchor:self.detailsView.layoutMarginsGuide.bottomAnchor].active = YES;
        imageView;
    });
    
    _label = ({
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.numberOfLines = 0;
        label.textColor = [UIColor gray3];
        label.text = [self contentString];
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
        [self.detailsView addSubview:label];
        [label.topAnchor constraintEqualToAnchor:self.detailsView.layoutMarginsGuide.topAnchor].active = YES;
        [label.leadingAnchor constraintEqualToAnchor:self.imageView.layoutMarginsGuide.trailingAnchor].active = YES;
        [label.bottomAnchor constraintEqualToAnchor:self.detailsView.layoutMarginsGuide.bottomAnchor].active = YES;
        
        if (self.type == InfoCollectionViewCellTypeNoFashion) {
            [label.trailingAnchor constraintEqualToAnchor:self.detailsView.layoutMarginsGuide.trailingAnchor].active = YES;
        }
        
        label;
    });
    
    if (self.type == InfoCollectionViewCellTypeNoShoppables) {
        _closeButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            [button setImage:[UIImage imageNamed:@"InfoCellX"] forState:UIControlStateNormal];
            button.contentEdgeInsets = UIEdgeInsetsMake(0.f, self.detailsView.layoutMargins.left, 0.f, self.detailsView.layoutMargins.left);
            [self.detailsView addSubview:button];
            [button setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            [button setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            [button.topAnchor constraintEqualToAnchor:self.detailsView.topAnchor].active = YES;
            [button.leadingAnchor constraintEqualToAnchor:self.label.trailingAnchor].active = YES;
            [button.bottomAnchor constraintEqualToAnchor:self.detailsView.bottomAnchor].active = YES;
            [button.trailingAnchor constraintEqualToAnchor:self.detailsView.trailingAnchor].active = YES;
            button;
        });
    }
}

- (CGFloat)buttonHeight {
    return 50.f;
}

- (void)setupButtonsView {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor background];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mainView addSubview:view];
    [view.topAnchor constraintEqualToAnchor:self.detailsView.bottomAnchor].active = YES;
    [view.leadingAnchor constraintEqualToAnchor:self.mainView.leadingAnchor].active = YES;
    [view.bottomAnchor constraintEqualToAnchor:self.mainView.bottomAnchor].active = YES;
    [view.trailingAnchor constraintEqualToAnchor:self.mainView.trailingAnchor].active = YES;
    
    _closeButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button setTitle:@"No" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor crazeRed] forState:UIControlStateNormal];
        [view addSubview:button];
        [button.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
        [button.leadingAnchor constraintEqualToAnchor:view.leadingAnchor].active = YES;
        [button.bottomAnchor constraintEqualToAnchor:view.bottomAnchor].active = YES;
        [button.trailingAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
        [button.heightAnchor constraintEqualToConstant:[self buttonHeight]].active = YES;
        button;
    });
    
    _continueButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button setTitle:@"Yes" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor crazeGreen] forState:UIControlStateNormal];
        [view addSubview:button];
        [button.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
        [button.leadingAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
        [button.bottomAnchor constraintEqualToAnchor:view.bottomAnchor].active = YES;
        [button.trailingAnchor constraintEqualToAnchor:view.trailingAnchor].active = YES;
        [button.heightAnchor constraintEqualToConstant:[self buttonHeight]].active = YES;
        button;
    });
    
    UIView *border = [[UIView alloc] init];
    border.translatesAutoresizingMaskIntoConstraints = NO;
    border.backgroundColor = [UIColor gray6];
    [view addSubview:border];
    [border.centerXAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
    [border.centerYAnchor constraintEqualToAnchor:view.centerYAnchor].active = YES;
    [border.widthAnchor constraintEqualToConstant:1.f].active = YES;
    [border.heightAnchor constraintEqualToConstant:[self buttonHeight] * .6f].active = YES;
}

- (void)removeViews {
    if (self.mainView.subviews.count) {
        [self.mainView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    
    _closeButton = nil;
    _continueButton = nil;
}

- (NSString *)contentString {
    switch (self.type) {
        case InfoCollectionViewCellTypeNoShoppables:
            return @"No fashion items were detected in your latest screenshot";
            break;
            
        case InfoCollectionViewCellTypeNoFashion:
            return @"Your latest screenshot was not detected as fashion-related.\nScan for items anyway?";
            break;
    }
}


#pragma mark - Size

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat labelWidth = ({
        CGFloat usedWidth = 0.f;
        
        if (self.type == InfoCollectionViewCellTypeNoShoppables) {
            usedWidth = self.detailsView.layoutMargins.left + self.imageView.image.size.width + fabs(self.imageView.layoutMargins.right) + self.closeButton.contentEdgeInsets.left + [self.closeButton imageForState:UIControlStateNormal].size.width + self.closeButton.contentEdgeInsets.right;
            
        } else if (self.type == InfoCollectionViewCellTypeNoFashion) {
            usedWidth = self.detailsView.layoutMargins.left + self.imageView.image.size.width + fabs(self.imageView.layoutMargins.right) + self.detailsView.layoutMargins.right;
        }
        
        size.width - usedWidth;
    });
    
    CGRect boundingRect = [self.label.text boundingRectWithSize:CGSizeMake(labelWidth, 0.f) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.label.font} context:nil];
    
    size.height = ({
        CGFloat height = 0.f;
        
        if (self.type == InfoCollectionViewCellTypeNoShoppables) {
            height = self.detailsView.layoutMargins.top + ceil(boundingRect.size.height) + self.detailsView.layoutMargins.bottom;
            
        } else if (self.type == InfoCollectionViewCellTypeNoFashion) {
            height = self.detailsView.layoutMargins.top + ceil(boundingRect.size.height) + self.detailsView.layoutMargins.bottom + [self buttonHeight];
        }
        
        height;
    });
    
    return size;
}

@end
