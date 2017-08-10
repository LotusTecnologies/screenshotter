//
//  ScreenshotImage.m
//  screenshot
//
//  Created by Corey Werner on 8/10/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotImage.h"

@implementation ScreenshotImage

+ (ScreenshotImage *)screenshot:(Screenshot *)screenshot handler:(ScreenshotImageHandler)handler {
    return [[ScreenshotImage alloc] initWithScreenshot:screenshot handler:handler];
}

- (instancetype)initWithScreenshot:(Screenshot *)screenshot handler:(ScreenshotImageHandler)handler {
    self = [super init];
    if (self) {
        _screenshot = screenshot;
        
        if (screenshot && handler) {
            if (screenshot.imageData != nil) {
                UIImage *image = [UIImage imageWithData:screenshot.imageData];
                handler(image, screenshot);
            } else {
                [AssetSyncModel.sharedInstance imageWithAssetId:screenshot.assetId callback:^(UIImage *image){
                    handler(image, screenshot);
                    screenshot.imageData = UIImageJPEGRepresentation(image, 0.95);
                }];
            }
        }
    }
    return self;
}


@end
