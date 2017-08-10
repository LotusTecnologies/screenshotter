//
//  MatchModel.m
//  screenshot
//
//  Created by Gershon Kagan on 6/28/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "MatchModel.h"
#import "NetworkingModel.h"
#import "screenshot-Swift.h"
@import Photos;
@import UserNotifications;

@interface MatchModel () <PHPhotoLibraryChangeObserver>

@property(strong, nonatomic) ClarifaiApp *app;
@property(strong, nonatomic) PHFetchResult<PHAsset *> *assets;

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
        self.app = [[ClarifaiApp alloc] initWithApiKey:@"b0c68b58001546afa6e9cbe0f8f619b2"];
//        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
//        UNAuthorizationOptions options = UNAuthorizationOptionAlert + UNAuthorizationOptionSound;
//        [center requestAuthorizationWithOptions:options
//                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
//                                  if (!granted) {
//                                      NSLog(@"Something went wrong");
//                                  }
//                              }];
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
//        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationUserDidTakeScreenshotNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
//            NSLog(@"observer hit for UIApplicationUserDidTakeScreenshotNotification");
//        }];
    }
    return self;
}

- (void)dealloc
{
//    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

-(void)latestScreenshotWithCallback:(void (^)(UIImage *))callback {
    PHFetchOptions *lastScreenshotOptions = [[PHFetchOptions alloc] init];
    lastScreenshotOptions.predicate = [NSPredicate predicateWithFormat:@"mediaSubtype == %lu", PHAssetMediaSubtypePhotoScreenshot];
    lastScreenshotOptions.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO] ];
    lastScreenshotOptions.fetchLimit = 1;

    self.assets = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:lastScreenshotOptions];
    
    PHAsset *lastScreenshotAsset = self.assets.firstObject;
    if (lastScreenshotAsset == nil) {
        NSLog(@"No lastScreenshotAsset. assets:%@", self.assets);
        callback(nil);
        return;
    }
    
    Screenshot *screenshot = [DataModel.sharedInstance lastSavedScreenshotBackground];
    if (![screenshot.assetId isEqualToString:lastScreenshotAsset.localIdentifier]) {
        screenshot = [DataModel.sharedInstance saveScreenshotWithAssetId:lastScreenshotAsset.localIdentifier];
    }

    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.synchronous = NO;
    imageRequestOptions.version = PHImageRequestOptionsVersionCurrent;
    imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeNone;
    imageRequestOptions.networkAccessAllowed = YES;
    [[PHImageManager defaultManager] requestImageDataForAsset:lastScreenshotAsset options:imageRequestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        UIImage *lastScreenshotImage = [UIImage imageWithData:imageData];
        NSLog(@"lastScreenshotImage size:%@", NSStringFromCGSize(lastScreenshotImage.size));
        callback(lastScreenshotImage);
    }];
}

-(void)isFashion:(UIImage *)image completion:(ClarifaiPredictionsCompletion)completion {
    [self.app getModelByName:@"general-v1.3" completion:^(ClarifaiModel *model, NSError *error) {
        ClarifaiImage *clarifaiImage = [[ClarifaiImage alloc] initWithImage:image];
        [model predictOnImages:@[clarifaiImage]
                    completion:^(NSArray<ClarifaiOutput *> *outputs, NSError *error) {
                        if (completion)
                            completion(outputs, error);
                    }];
    }];
}

-(void)logClarifaiSyteInitial:(void(^_Nonnull)(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error))completionhandler {
    [self latestScreenshotWithCallback:^(UIImage *pickedImage) {
        self.lastScreenshot = pickedImage;
        if (pickedImage == nil) {
            NSLog(@"ERROR latestScreenshotWithCallback returned nothing");
            NSURLResponse *resp = [[NSURLResponse alloc] init];
            completionhandler(resp, nil, nil);
        } else {
            NSLog(@"image size:%@  scale:%.1f\n", NSStringFromCGSize(pickedImage.size), pickedImage.scale);
            [self isFashion:pickedImage completion:^(NSArray<ClarifaiOutput *> *outputs, NSError *error) {
                BOOL isFashion = NO;
                NSInteger j = 0;
                for (ClarifaiOutput *output in outputs) {
                    for (ClarifaiConcept *concept in output.concepts) {
                        if (   [concept.conceptName isEqualToString:@"woman"]
                            || [concept.conceptName isEqualToString:@"fashion"]
                            || [concept.conceptName isEqualToString:@"beauty"]
                            || [concept.conceptName isEqualToString:@"glamour"]
                            || [concept.conceptName isEqualToString:@"dress"]) {
                            isFashion = YES;
                        }
                        NSLog(@"%.2ld  %f  %@\n", (long)++j, concept.score * 100.0f, concept.conceptName);
                    }
                }
                NSLog(@"isFashion:%@\n", (isFashion ? @"YES" : @"NO"));
                DataModel *dataModel = DataModel.sharedInstance;
                Screenshot *screenshot = [dataModel lastSavedScreenshotMain];
                screenshot.isFashion = @(isFashion);
                if (isFashion) {
                    NSData *imageData = UIImageJPEGRepresentation(pickedImage, 0.95);
                    screenshot.imageData = imageData;
                    [dataModel saveMain];
                    [NetworkingModel uploadToSyte:imageData completionHandler:completionhandler];
                } else {
                    [dataModel saveMain];
                    NSURLResponse *resp = [[NSURLResponse alloc] init];
                    completionhandler(resp, nil, nil);
                }
            }];
        }
    }];
}

#pragma mark - PHPhotoLibraryChangeObserver

-(void)photoLibraryDidChange:(PHChange *)changeInfo {
    NSLog(@"photoLibraryDidChange changeInfo:%@", changeInfo);
    PHFetchResultChangeDetails *collectionChanges = [changeInfo changeDetailsForFetchResult:self.assets];
    if (collectionChanges.hasIncrementalChanges && collectionChanges.insertedIndexes.count > 0) {
        NSLog(@"photoLibraryDidChange hasIncrementalChanges and insertedIndexes");
        [self logClarifaiSyteInitial:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                       if (error) {
                           NSLog(@"logClarifaiSyteInitial error:%@", error);
                       } else {
                           NSLog(@"logClarifaiSyteInitial response:%@\nresponseObject:%@", response, responseObject);
                       }
                   }
        ];
    }
}

@end
