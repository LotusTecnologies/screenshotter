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
-(void)logClarifaiSyteInitial:(NSMutableString *)logString completionHandler:(void(^_Nonnull)(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error))completionhandler;


-(void)latestScreenshotWithCallback:(void (^)(UIImage *))callback;
-(void)matchImage:(UIImage *)image completion:(ClarifaiSearchCompletion)completion;
-(void)isFashion:(UIImage *)image completion:(ClarifaiPredictionsCompletion)completion;

@end
