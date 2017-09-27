//
//  TutorialEmailSlideView.m
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialEmailSlideView.h"
#import "Geometry.h"
#import "TappableTextView.h"
#import "WebViewController.h"
#import "AnalyticsManager.h"
#import "screenshot-Swift.h"

@interface TutorialEmailSlideView () <UITextFieldDelegate, TappableTextViewDelegate>

@property (nonatomic) BOOL readyToSubmit;

@property (nonatomic, strong) UITextField *nameTextField;
@property (nonatomic, strong) UITextField *emailTextField;
@property (nonatomic, strong) MainButton *button;
@property (nonatomic, strong) TappableTextView *textView;

@property (nonatomic, strong) NSLayoutConstraint *expandableViewHeightConstraint;
@property (nonatomic) CGRect keyboardFrame;

@end

@implementation TutorialEmailSlideView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.text = @"Sign Up";
        self.subtitleLabel.text = @"Fill out your info below";
        
        CGFloat p = [Geometry padding];
        
        UILabel *nameLabel = [[UILabel alloc] init];
        nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        nameLabel.text = @"Your name:";
        nameLabel.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, -5.f, 0.f);
        [self.contentView addSubview:nameLabel];
        [nameLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [nameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:30.f].active = YES;
        [nameLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [nameLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:nameLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:400.f];
        widthConstraint.priority = UILayoutPriorityDefaultHigh;
        widthConstraint.active = YES;
        
        _nameTextField = ({
            UITextField *textField = [[UITextField alloc] init];
            textField.translatesAutoresizingMaskIntoConstraints = NO;
            textField.delegate = self;
            textField.text = [[NSUserDefaults standardUserDefaults] valueForKey:UserDefaultsKeys.name];
            textField.placeholder = @"Enter your name";
            textField.backgroundColor = [UIColor whiteColor];
            textField.borderStyle = UITextBorderStyleRoundedRect;
            textField.returnKeyType = UIReturnKeyNext;
            textField.spellCheckingType = UITextSpellCheckingTypeNo;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, -p, 0.f);
            [self.contentView addSubview:textField];
            [textField setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
            [textField.topAnchor constraintEqualToAnchor:nameLabel.layoutMarginsGuide.bottomAnchor].active = YES;
            [textField.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor].active = YES;
            [textField.trailingAnchor constraintEqualToAnchor:nameLabel.trailingAnchor].active = YES;
            [textField.heightAnchor constraintEqualToConstant:50.f].active = YES;
            textField;
        });
        
        UILabel *emailLabel = [[UILabel alloc] init];
        emailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        emailLabel.text = @"Your email:";
        emailLabel.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, -5.f, 0.f);
        [self.contentView addSubview:emailLabel];
        [emailLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [emailLabel.topAnchor constraintEqualToAnchor:self.nameTextField.layoutMarginsGuide.bottomAnchor constant:20.f].active = YES;
        [emailLabel.leadingAnchor constraintEqualToAnchor:self.nameTextField.leadingAnchor].active = YES;
        [emailLabel.trailingAnchor constraintEqualToAnchor:self.nameTextField.trailingAnchor].active = YES;
        
        _emailTextField = ({
            UITextField *textField = [[UITextField alloc] init];
            textField.translatesAutoresizingMaskIntoConstraints = NO;
            textField.delegate = self;
            textField.text = [[NSUserDefaults standardUserDefaults] valueForKey:UserDefaultsKeys.email];
            textField.placeholder = @"yourname@website.com";
            textField.keyboardType = UIKeyboardTypeEmailAddress;
            textField.backgroundColor = [UIColor whiteColor];
            textField.borderStyle = UITextBorderStyleRoundedRect;
            textField.spellCheckingType = UITextSpellCheckingTypeNo;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            [self.contentView addSubview:textField];
            [textField setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
            [textField.topAnchor constraintEqualToAnchor:emailLabel.layoutMarginsGuide.bottomAnchor].active = YES;
            [textField.leadingAnchor constraintEqualToAnchor:emailLabel.leadingAnchor].active = YES;
            [textField.trailingAnchor constraintEqualToAnchor:emailLabel.trailingAnchor].active = YES;
            [textField.heightAnchor constraintEqualToAnchor:self.nameTextField.heightAnchor].active = YES;
            textField;
        });
        
        _button = ({
            MainButton *button = [MainButton buttonWithType:UIButtonTypeCustom];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            [button setTitle:@"Submit" forState:UIControlStateNormal];
            [button addTarget:self action:@selector(submitEmail) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:button];
            [button setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            [button setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            [button.topAnchor constraintEqualToAnchor:self.emailTextField.bottomAnchor constant:40.f].active = YES;
            [button.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
            [button.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            [button.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
            button;
        });
        
        _textView = ({
            TappableTextView *textView = [[TappableTextView alloc] init];
            textView.delegate = self;
            textView.translatesAutoresizingMaskIntoConstraints = NO;
            textView.backgroundColor = [UIColor clearColor];
            textView.textColor = [UIColor gray6];
            textView.textAlignment = NSTextAlignmentCenter;
            textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
            textView.editable = NO;
            textView.scrollEnabled = NO;
            textView.scrollsToTop = NO;
            [self.contentView addSubview:textView];
            [textView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            [textView.topAnchor constraintGreaterThanOrEqualToAnchor:self.button.bottomAnchor constant:p].active = YES;
            [textView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
            [textView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
            [textView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            
            NSArray *tappableText = @[@{@"By tapping \"Submit\" above, you agree to our\n ": @NO},
                                      @{@"Terms of Service": @YES},
                                      @{@" and ": @NO},
                                      @{@"Privacy Policy": @YES},
                                      @{@" ": @NO}
                                      ];
            
            NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
            paragraph.alignment = textView.textAlignment;
            
            NSDictionary *attributes = @{NSFontAttributeName: textView.font,
                                         NSParagraphStyleAttributeName: paragraph
                                         };
            
            [textView applyTappableText:tappableText withAttributes:attributes];
            textView;
        });
        
        UIView *expandableView = [[UIView alloc] init];
        expandableView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:expandableView];
        [expandableView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        _expandableViewHeightConstraint = [NSLayoutConstraint constraintWithItem:expandableView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:0.f];
        self.expandableViewHeightConstraint.active = YES;
        
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignTextField)]];
    }
    return self;
}

- (void)didEnterSlide {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)willLeaveSlide {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.textView.delegate = nil;
}


#pragma mark - Submit

- (void)submitEmail {
    if ([self.emailTextField.text isValidEmail]) {
        self.readyToSubmit = YES;
        
        NSString *trimmedName = [self.nameTextField.text trimWhitespace];
        NSString *trimmedEmail = [self.emailTextField.text trimWhitespace];
        
        [[NSUserDefaults standardUserDefaults] setValue:trimmedName forKey:UserDefaultsKeys.name];
        [[NSUserDefaults standardUserDefaults] setValue:trimmedEmail forKey:UserDefaultsKeys.email];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self informDelegateOfSubmittedEmailIfPossible];
        
        [AnalyticsManager track:@"Submitted email" properties:@{@"name": trimmedName, @"email": trimmedEmail}];
        [AnalyticsManager identify:trimmedEmail name:trimmedName];
        
    } else {
        [self.delegate tutorialEmailSlideViewDidFailValidation:self];
    }
    
    [self.emailTextField resignFirstResponder];
}

- (void)informDelegateOfSubmittedEmailIfPossible {
    if (![self.emailTextField isFirstResponder] && self.readyToSubmit) {
        [self resignTextField];
        [self.delegate tutorialEmailSlideViewDidComplete:self];
    }
}


#pragma mark - Text Field

- (void)resignTextField {
    [self endEditing:YES];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Wait until the keyboardFrame has been set.
        
        CGRect toWindowRect = [self convertRect:self.frame toView:self.window];
        CGFloat bottomOffset = self.window.bounds.size.height - CGRectGetMaxY(toWindowRect) + self.button.bounds.size.height;
        self.expandableViewHeightConstraint.constant = MAX(self.keyboardFrame.size.height - bottomOffset, 0);
        
        [UIView animateWithDuration:0.25 animations:^{
            [self.contentView layoutIfNeeded];
        }];
    });
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.expandableViewHeightConstraint.constant = 0;
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.contentView layoutIfNeeded];
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.nameTextField) {
        [self.emailTextField becomeFirstResponder];
        
    } else {
        [textField resignFirstResponder];
    }
    
    return YES;
}


#pragma mark - Text View

- (void)tappableTextView:(TappableTextView *)textView tappedTextAtIndex:(NSUInteger)index {
    if (index == 1) {
        [self.delegate tutorialEmailSlideViewDidTapTermsOfService:self];
        
    } else if (index == 3) {
        [self.delegate tutorialEmailSlideViewDidTapPrivacyPolicy:self];
    }
}


#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification {
    if (self.window) {
        self.keyboardFrame = [[[notification userInfo] valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    }
}

- (void)keyboardDidHide:(NSNotification *)notification {
    if (self.window) {
        [self informDelegateOfSubmittedEmailIfPossible];
    }
}


#pragma mark - Alert

- (UIAlertController *)failedAlertController {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Submission Failed" message:@"Please enter a valid email." preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
    return alertController;
}


#pragma mark - Legal

+ (UIViewController *)termsOfServiceViewControllerWithDoneTarget:(id)target doneAction:(SEL)action {
    NSString *title = @"Terms of Service";
    NSURL *url = [NSURL URLWithString:@"http://crazeapp.com/legal/#tos"];
    
    return [self webViewControllerWithTitle:title url:url doneTarget:target doneAction:action];
}

+ (UIViewController *)privacyPolicyViewControllerWithDoneTarget:(id)target doneAction:(SEL)action {
    NSString *title = @"Privacy Policy";
    NSURL *url = [NSURL URLWithString:@"http://crazeapp.com/legal/#privacy"];
    
    return [self webViewControllerWithTitle:title url:url doneTarget:target doneAction:action];
}

+ (UIViewController *)webViewControllerWithTitle:(NSString *)title url:(NSURL *)url doneTarget:(id)target doneAction:(SEL)action {
    WebViewController *viewController = [[WebViewController alloc] init];
    viewController.url = url;
    viewController.toolbarEnabled = NO;
    viewController.navigationItem.title = title;
    viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:target action:action];
    
    return [[UINavigationController alloc] initWithRootViewController:viewController];
}

@end
