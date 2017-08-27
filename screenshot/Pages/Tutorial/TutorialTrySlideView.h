//
//  TutorialTrySlideView.h
//  screenshot
//
//  Created by Corey Werner on 8/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialBaseSlideView.h"

@class TutorialTrySlideView;

@protocol TutorialTrySlideViewDelegate <NSObject>
@required

- (void)tutorialTrySlideViewDidComplete:(TutorialTrySlideView *)slideView;

@end

@interface TutorialTrySlideView : TutorialBaseSlideView

@property (nonatomic, weak) id<TutorialTrySlideViewDelegate> delegate;

@end
