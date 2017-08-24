//
//  TutorialWelcomeSlideView.h
//  screenshot
//
//  Created by Corey Werner on 8/24/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialBaseSlideView.h"

@class TutorialWelcomeSlideView;

@protocol TutorialWelcomeSlideViewDelegate <NSObject>
@required

- (void)tutorialWelcomeSlideViewDidComplete:(TutorialWelcomeSlideView *)slideView;

@end

@interface TutorialWelcomeSlideView : TutorialBaseSlideView

@property (nonatomic, weak) id<TutorialWelcomeSlideViewDelegate> delegate;

@end
