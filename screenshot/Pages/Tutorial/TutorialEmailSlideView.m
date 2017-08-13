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

@property (nonatomic) BOOL readyToSubmit;

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) NSLayoutConstraint *expandableViewHeightConstraint;

@end

@implementation TutorialEmailSlideView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHideNotification:) name:UIKeyboardDidHideNotification object:nil];
        
        self.titleLabel.text = @"Almost Done!";
        
        CGFloat p = [Geometry padding];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Mail"]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, -p, 0.f);
        [self.contentView addSubview:imageView];
        [imageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        [imageView.topAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor].active = YES;
        [imageView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [imageView.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [imageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
        
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.text = @"Enter you email:";
        label.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, -5.f, 0.f);
        [self.contentView addSubview:label];
        [label setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        [label.topAnchor constraintGreaterThanOrEqualToAnchor:imageView.layoutMarginsGuide.bottomAnchor].active = YES;
        [label.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [label.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:400.f];
        widthConstraint.priority = UILayoutPriorityDefaultHigh;
        widthConstraint.active = YES;
        
        UITextField *textField = [[UITextField alloc] init];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        textField.delegate = self;
        textField.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"Email"];
        textField.placeholder = @"you@website.com";
        textField.keyboardType = UIKeyboardTypeEmailAddress;
        textField.returnKeyType = UIReturnKeyDone;
        textField.backgroundColor = [UIColor whiteColor];
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, -p, 0.f);
        [self.contentView addSubview:textField];
        [textField setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [textField.topAnchor constraintEqualToAnchor:label.layoutMarginsGuide.bottomAnchor].active = YES;
        [textField.leadingAnchor constraintEqualToAnchor:label.leadingAnchor].active = YES;
        [textField.trailingAnchor constraintEqualToAnchor:label.trailingAnchor].active = YES;
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
        [button setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        [button.topAnchor constraintGreaterThanOrEqualToAnchor:textField.layoutMarginsGuide.bottomAnchor];
        [button.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [button.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor];
        [button.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [button.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
        
        UIView *expandableView = [[UIView alloc] init];
        expandableView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:expandableView];
        [expandableView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        self.expandableViewHeightConstraint = [NSLayoutConstraint constraintWithItem:expandableView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:0.f];
        self.expandableViewHeightConstraint.active = YES;
        [self separatorFromAnchor:self.contentView.topAnchor toAnchor:imageView.topAnchor];
        [self separatorFromAnchor:imageView.bottomAnchor toAnchor:label.topAnchor];
        [self separatorFromAnchor:textField.bottomAnchor toAnchor:button.topAnchor];
        [self separatorFromAnchor:button.bottomAnchor toAnchor:expandableView.topAnchor];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignTextField)];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}


#pragma mark - Submit

- (BOOL)isValidEmail:(NSString *)email {
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
//    NSString *emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex] evaluateWithObject:email];
}

- (void)submitEmail {
    if ([self isValidEmail:self.textField.text]) {
        self.readyToSubmit = YES;
        
        [[NSUserDefaults standardUserDefaults] setValue:self.textField.text forKey:@"Email"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self informDelegateOfSubmittedEmailIfPossible];
        
    } else {
        // TODO: create delegate informing the submitted email is invalid
    }
    
    [self.textField resignFirstResponder];
}

- (void)informDelegateOfSubmittedEmailIfPossible {
    if (![self.textField isFirstResponder] && self.readyToSubmit) {
        [self.delegate tutorialEmailSlideViewDidSubmit:self];
    }
}


#pragma mark - Text Field

- (void)resignTextField {
    [self.textField resignFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // TODO: constant should be height of keyboard (when in portrait!)
    self.expandableViewHeightConstraint.constant = [UIScreen mainScreen].bounds.size.height * .2f;
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.contentView layoutIfNeeded];
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.expandableViewHeightConstraint.constant = 0;
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.contentView layoutIfNeeded];
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self submitEmail];
    return YES;
}


#pragma mark - Keyboard

- (void)keyboardDidHideNotification:(NSNotification *)notification {
    [self informDelegateOfSubmittedEmailIfPossible];
}

@end
