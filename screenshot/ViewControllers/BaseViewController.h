//
//  BaseViewController.h
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "LifeCycleProtocol.h"

@protocol ViewControllerLifeCycle;

@interface BaseViewController : UIViewController

@property (nonatomic, weak) id<ViewControllerLifeCycle> delegate;

- (void)addNavigationItemLogo;

@end
