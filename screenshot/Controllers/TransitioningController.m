//
//  TransitioningController.m
//  screenshot
//
//  Created by Corey Werner on 8/31/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TransitioningController.h"
#import "InsetPresentationController.h"

@interface TransitioningController ()

@end

@implementation TransitioningController

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source {
    return [[InsetPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
}

@end
