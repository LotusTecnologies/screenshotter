//
//  ScreenshotImage.h
//  screenshot
//
//  Created by Corey Werner on 8/10/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "screenshot-Swift.h"

typedef void (^ScreenshotImageHandler)(UIImage *image, Screenshot *screenshot);

@interface ScreenshotImage : NSObject

+ (ScreenshotImage *)screenshot:(Screenshot *)screenshot handler:(ScreenshotImageHandler)handler;
- (instancetype)initWithScreenshot:(Screenshot *)screenshot handler:(ScreenshotImageHandler)handler;

@property (nonatomic, strong, readonly) Screenshot *screenshot;

@end
