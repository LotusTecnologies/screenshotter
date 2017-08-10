//
//  ScreenshotImage.h
//  screenshot
//
//  Created by Corey Werner on 8/10/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "screenshot-Swift.h"

@interface ScreenshotImage : NSObject

+ (ScreenshotImage *)screenshot:(Screenshot *)screenshot handler:(void (^)(UIImage *image, Screenshot *screenshot))handler;
- (instancetype)initWithScreenshot:(Screenshot *)screenshot handler:(void (^)(UIImage *image, Screenshot *screenshot))handler;

@property (nonatomic, strong, readonly) Screenshot *screenshot;

@end
