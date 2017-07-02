//
//  MatchModel.h
//  screenshot
//
//  Created by Gershon Kagan on 6/28/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClarifaiApp.h"
@import UIKit;

@interface MatchModel : NSObject

+(instancetype)shared;

-(void)latestScreenshotWithCallback:(void (^)(UIImage *))callback;
-(void)matchImage:(UIImage *)image completion:(ClarifaiSearchCompletion)completion;

@end
