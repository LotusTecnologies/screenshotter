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
        NSURL *url;
        
        if (data) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            url = [NSURL URLWithString:[json objectForKey:@"short"]];
        }
        
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
