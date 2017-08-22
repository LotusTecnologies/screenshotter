//
//  ScreenshotImageFetcher.m
//  screenshot
//
//  Created by Corey Werner on 8/10/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotImageFetcher.h"

@implementation ScreenshotImageFetcher

+ (ScreenshotImageFetcher *)screenshot:(Screenshot *)screenshot handler:(ScreenshotImageHandler)handler {
    return [[ScreenshotImageFetcher alloc] initWithScreenshot:screenshot handler:handler];
}

- (instancetype)initWithScreenshot:(Screenshot *)screenshot handler:(ScreenshotImageHandler)handler {
    self = [super init];
    if (self) {
        if (screenshot && handler) {
            if (screenshot.imageData != nil) {
                handler([UIImage imageWithData:screenshot.imageData]);
                
            } else {
                [AssetSyncModel.sharedInstance imageWithAssetId:screenshot.assetId callback:^(UIImage *image, NSDictionary *info){
                    // TODO: the below code prevents the images showing immediatly. however with it removed th eUI is blocked
                    
                    // This callback may be called initially with degraded image. Wait for next one.
                    NSNumber *isDegraded = info[PHImageResultIsDegradedKey];
                    
                    if ([isDegraded boolValue]) {
                        return;
                    }
                    
                    handler(image);
                    screenshot.imageData = UIImageJPEGRepresentation(image, 0.95);
                }];
            }
        }
    }
    return self;
}

@end
