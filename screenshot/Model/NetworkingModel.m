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

+(void)downloadProductInfo:(NSURL * _Nonnull)url completionHandler:(void(^_Nonnull)(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error))completionhandler {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSLog(@"downloadProductInfo headers:%@  request.URL:%@  ", request.allHTTPHeaderFields, request.URL);

    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:completionhandler];
    [dataTask resume];
}

+ (void)shortenUrl:(NSURL * _Nonnull)url completion:(void(^_Nonnull)(NSURL * _Nullable url))completion {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateNow = [dateFormatter stringFromDate:[NSDate date]];
    
    NSDictionary *postDict = @{@"type": @"long", @"long": url.absoluteString, @"datePicker": dateNow};
    
    NSData *postData = [NSJSONSerialization dataWithJSONObject:postDict options:0 error:NULL];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://craz.me/shortener"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSURL *url = [NSURL URLWithString:[json objectForKey:@"short"]];
        
        if ([NSThread isMainThread]) {
            completion(url);
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(url);
            });
        }
    }];
    [dataTask resume];
}

@end
