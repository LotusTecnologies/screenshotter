//
//  TutorialEmailSlideView.m
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialEmailSlideView.h"
#import "UIColor+Appearance.h"
#import "Geometry.h"

@interface TutorialEmailSlideView () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *textField;

@end

@implementation TutorialEmailSlideView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.text = @"Almost Done!";
        
        CGFloat p = [Geometry padding];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Mail"]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, p, 0.f);
        [self.contentView addSubview:imageView];
        [imageView.topAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor].active = YES;
        [imageView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [imageView.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [imageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
        
        UITextField *textField = [[UITextField alloc] init];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        textField.delegate = self;
        textField.placeholder = @"you@website.com";
        textField.returnKeyType = UIReturnKeyDone;
        textField.backgroundColor = [UIColor whiteColor];
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, [Geometry padding], 0.f);
        [self.contentView addSubview:textField];
        [textField.topAnchor constraintGreaterThanOrEqualToAnchor:imageView.layoutMarginsGuide.bottomAnchor].active = YES;
        [textField.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [textField.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [textField.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
        self.textField = textField;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.backgroundColor = [UIColor crazeRedColor];
        [button setTitle:@"Submit" forState:UIControlStateNormal];
        button.contentEdgeInsets = UIEdgeInsetsMake(p * .5f, p, p * .5f, p);
        [button addTarget:self action:@selector(submitEmail) forControlEvents:UIControlEventTouchUpInside];
        button.layer.cornerRadius = 5.f;
        [self.contentView addSubview:button];
        [button setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [button.topAnchor constraintGreaterThanOrEqualToAnchor:textField.layoutMarginsGuide.bottomAnchor];
        [button.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [button.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor];
        [button.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [button.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
        
        [self separatorFromAnchor:self.contentView.topAnchor toAnchor:imageView.topAnchor];
        [self separatorFromAnchor:imageView.bottomAnchor toAnchor:textField.topAnchor];
        [self separatorFromAnchor:textField.bottomAnchor toAnchor:button.topAnchor];
        [self separatorFromAnchor:button.bottomAnchor toAnchor:self.contentView.bottomAnchor];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignTextField)];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}


#pragma mark - Submit

- (void)submitEmail {
    [[NSUserDefaults standardUserDefaults] setValue:self.textField.text forKey:@"Email"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.delegate tutorialEmailSlideViewDidSubmit:self];
}


#pragma mark - Text Field

- (void)resignTextField {
    [self.textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self submitEmail];
    [textField resignFirstResponder];
    return YES;
}

@end
