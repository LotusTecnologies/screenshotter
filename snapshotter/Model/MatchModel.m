//
//  MatchModel.m
//  snapshotter
//
//  Created by Gershon Kagan on 6/28/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "MatchModel.h"

@interface MatchModel ()

@property(strong, nonatomic) ClarifaiApp *app;

@end


@implementation MatchModel

+(instancetype)shared {
    static MatchModel *sharedMatchModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMatchModel = [[self alloc] init];
    });
    return sharedMatchModel;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        self.app = [[ClarifaiApp alloc] initWithAppID:@"fUpjePATM-F8H8v3JJpn3xUDpgr4PsA5DL0iNNSk" appSecret:@"3-nau88O0mZ9bNUh2tJI5JT72pbviuXl3Q9s54kc"];
    }
    return self;
}

-(void)matchImage:(UIImage *)image completion:(ClarifaiSearchCompletion)completion {
    ClarifaiSearchTerm *term = [ClarifaiSearchTerm searchVisuallyWithUIImage:image];
    [self.app search:@[term]
                page:@1
             perPage:@4
          completion:completion];
}

@end
