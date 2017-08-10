//
//  ScreenshotImage.m
//  screenshot
//
//  Created by Corey Werner on 8/10/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotImage.h"

@implementation ScreenshotImage

+ (ScreenshotImage *)screenshot:(Screenshot *)screenshot handler:(void (^)(UIImage *image, Screenshot *screenshot))handler {
    return [[ScreenshotImage alloc] initWithScreenshot:screenshot handler:handler];
}

- (instancetype)initWithScreenshot:(Screenshot *)screenshot handler:(void (^)(UIImage *image, Screenshot *))handler {
    self = [super init];
    if (self) {
        _screenshot = screenshot;
        
        if (handler) {
            // TODO: get screenshot image
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                UIImage *image;
                
                handler(image, screenshot);
            });
        }
    }
    return self;
}


@end
