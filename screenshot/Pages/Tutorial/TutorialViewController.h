//
//  TutorialViewController.h
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TutorialViewController;

@protocol TutorialViewControllerDelegate <NSObject>
@required

- (void)tutorialViewControllerDidComplete:(TutorialViewController *)viewController;

@end

@interface TutorialViewController : UIViewController

@property (nonatomic, weak) id<TutorialViewControllerDelegate> delegate;

@end
