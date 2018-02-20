//
//  ScreenshotsViewController.h
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//
#import <CoreData/CoreData.h>
#import "BaseViewController.h"
typedef NS_ENUM(NSInteger, ScreenshotsSection) {
    ScreenshotsSectionProduct,
    ScreenshotsSectionNotification,
    ScreenshotsSectionImage
};
@class ScreenshotsViewController;
@class Screenshot;
@class FetchedResultsControllerManager, ProductsBarController, ScreenshotsDeleteButton, ScreenshotCollectionViewCell;

@protocol ScreenshotsViewControllerDelegate <NSObject>
@required

- (void)screenshotsViewController:(ScreenshotsViewController *)viewController didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)screenshotsViewControllerDeletedLastScreenshot:(ScreenshotsViewController *)viewController;
- (void)screenshotsViewControllerWantsToPresentPicker:(ScreenshotsViewController *)viewController;

@end

@interface ScreenshotsViewController : BaseViewController

@property (nonatomic, weak) id<ScreenshotsViewControllerDelegate> delegate;

- (Screenshot *)screenshotAtIndex:(NSInteger)index;
- (NSInteger)indexForScreenshot:(Screenshot *)screenshot;

- (void)scrollToTop;

- (void)presentNotificationCellWithAssetId:(NSString *)assetId;
- (void)dismissNotificationCell;

//Made public so it can be used by swift
@property (nonatomic, strong) id screenshotFrcManager;
- (void)syncHelperViewVisibility;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<NSManagedObjectID *> *toUnfavoriteAndUnViewProductObjectIDs;
@property (nonatomic, strong) NSMutableArray<NSManagedObjectID *> *deleteScreenshotObjectIDs;

    @property (nonatomic, strong) ProductsBarController *productsBarController;
    @property (nonatomic, strong) ScreenshotsDeleteButton *deleteButton;
- (BOOL)hasNewScreenshot ;
    - (void)syncScreenshotCollectionViewCellSelectedState:(ScreenshotCollectionViewCell *)cell ;
@end
