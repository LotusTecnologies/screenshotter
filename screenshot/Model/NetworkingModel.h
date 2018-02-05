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

+ (void)shortenUrl:(NSURL * _Nonnull)url completion:(void(^_Nonnull)(NSURL * _Nullable url))completion;

@end
