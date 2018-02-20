//
//  ScreenshotsViewController.h
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//
#import <CoreData/CoreData.h>
#import "BaseViewController.h"
@class ScreenshotsViewController;
@class Screenshot;
@class FetchedResultsControllerManager, ProductsBarController, ScreenshotsDeleteButton, ScreenshotCollectionViewCell,ScreenshotsHelperView;

@protocol ScreenshotsViewControllerDelegate <NSObject>
@required

- (void)screenshotsViewController:(ScreenshotsViewController *)viewController didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)screenshotsViewControllerDeletedLastScreenshot:(ScreenshotsViewController *)viewController;
- (void)screenshotsViewControllerWantsToPresentPicker:(ScreenshotsViewController *)viewController;

@end

@interface ScreenshotsViewController : BaseViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) id<ScreenshotsViewControllerDelegate> delegate;

- (Screenshot *)screenshotAtIndex:(NSInteger)index;
- (NSInteger)indexForScreenshot:(Screenshot *)screenshot;

- (void)scrollToTop;


//Made public so it can be used by swift
@property (nonatomic, strong) id screenshotFrcManager;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<NSManagedObjectID *> *toUnfavoriteAndUnViewProductObjectIDs;
@property (nonatomic, strong) NSMutableArray<NSManagedObjectID *> *deleteScreenshotObjectIDs;

    @property (nonatomic, strong) ProductsBarController *productsBarController;
    @property (nonatomic, strong) ScreenshotsDeleteButton *deleteButton;
    @property (nonatomic, strong) UIRefreshControl *refreshControl;
    @property (nonatomic, strong) ScreenshotsHelperView *helperView;
- (CGPoint)collectionViewInteritemOffset ;
    @property (nonatomic, assign) BOOL hasNewScreenshot;

    @property (nonatomic, strong) NSDate *lastVisited;
    
    @property (nonatomic, copy) NSString *notificationCellAssetId;

@end
