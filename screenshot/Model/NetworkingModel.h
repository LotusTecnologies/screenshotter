//
//  NetworkingModel.h
//  screenshot
//
//  Created by Gershon Kagan on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NetworkingModel : NSObject

+(void)uploadToSyte:(NSData * _Nonnull)imageData completionHandler:(void(^_Nonnull)(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error))completionhandler;

+ (void)shortenUrl:(NSURL * _Nonnull)url completion:(void(^_Nonnull)(NSURL * _Nullable url))completion;

@end
