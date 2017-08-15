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

- (void)tutorialEmailSlideViewDidFail:(TutorialEmailSlideView *)slideView;
- (void)tutorialEmailSlideViewDidSubmit:(TutorialEmailSlideView *)slideView;

@end

@interface TutorialEmailSlideView : TutorialBaseSlideView

@property (nonatomic, weak) id<TutorialEmailSlideViewDelegate> delegate;

+ (UIAlertController *)failedAlertController;

@end
