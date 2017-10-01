//
//  TutorialEmailSlideView.h
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialBaseSlideView.h"

@class TutorialEmailSlideView;

@protocol TutorialEmailSlideViewDelegate <NSObject>
@required

- (void)tutorialEmailSlideViewDidComplete:(TutorialEmailSlideView *)slideView;

- (void)tutorialEmailSlideViewDidTapTermsOfService:(TutorialEmailSlideView *)slideView;
- (void)tutorialEmailSlideViewDidTapPrivacyPolicy:(TutorialEmailSlideView *)slideView;

@end

@interface TutorialEmailSlideView : TutorialBaseSlideView

@property (nonatomic, weak) id<TutorialEmailSlideViewDelegate> delegate;

- (UIAlertController *)failedAlertController;

+ (UIViewController *)termsOfServiceViewControllerWithDoneTarget:(id)target doneAction:(SEL)action;
+ (UIViewController *)privacyPolicyViewControllerWithDoneTarget:(id)target doneAction:(SEL)action;

@end
