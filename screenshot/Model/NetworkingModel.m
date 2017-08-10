//
//  NetworkingModel.m
//  screenshot
//
//  Created by Gershon Kagan on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "NetworkingModel.h"
#import <AFNetworking/AFNetworking.h>

@implementation NetworkingModel

+(void)uploadToSyte:(NSData *_Nonnull)imageData completionHandler:(void(^_Nonnull)(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error))completionhandler {
    NSDictionary *dictParams = @{@"account_id"      : @(6677),
                                 @"sig"             : @"GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU=",
                                 @"feed"            : @"default",
                                 @"payload_type"    : @"image_bin"};
    NSString *strService = @"https://syteapi.com/offers/bb";
    
    NSError *error;
    
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    serializer.HTTPMethodsEncodingParametersInURI = [serializer.HTTPMethodsEncodingParametersInURI setByAddingObject:@"POST"];
    
    NSMutableURLRequest *request = [serializer requestWithMethod:@"POST" URLString:strService parameters:dictParams error:&error];

    NSLog(@"uploadToSyte headers:%@  request.URL:%@  ", request.allHTTPHeaderFields, request.URL);
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionUploadTask *uploadTask;
    uploadTask = [manager uploadTaskWithRequest:request
                                       fromData:imageData
                                       progress:^(NSProgress * _Nonnull uploadProgress) { NSLog(@"Wrote %f", uploadProgress.fractionCompleted); }
                              completionHandler:completionhandler];

    [uploadTask resume];
}

@end
