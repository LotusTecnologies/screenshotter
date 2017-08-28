//
//  TutorialPermissionsSlideView.h
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialBaseSlideView.h"

@class TutorialPermissionsSlideView;

@protocol TutorialPermissionsSlideViewDelegate <NSObject>
@required

- (void)tutorialPermissionsSlideViewDidDenyPhotosPermission:(TutorialPermissionsSlideView *)slideView;
- (void)tutorialPermissionsSlideViewDidComplete:(TutorialPermissionsSlideView *)slideView;

@end

@interface TutorialPermissionsSlideView : TutorialBaseSlideView

@property (nonatomic, weak) id<TutorialPermissionsSlideViewDelegate> delegate;

- (UIAlertController *)determinePushAlertController;

@end
