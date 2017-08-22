//
//  ScreenshotImageFetcher.h
//  screenshot
//
//  Created by Corey Werner on 8/10/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "screenshot-Swift.h"

typedef void (^ScreenshotImageHandler)(UIImage *image);

@interface ScreenshotImageFetcher : NSObject

+ (ScreenshotImageFetcher *)screenshot:(Screenshot *)screenshot handler:(ScreenshotImageHandler)handler;
- (instancetype)initWithScreenshot:(Screenshot *)screenshot handler:(ScreenshotImageHandler)handler;

@end
