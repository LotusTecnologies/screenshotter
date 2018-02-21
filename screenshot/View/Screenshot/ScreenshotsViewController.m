//
//  ScreenshotsViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//


#import "ScreenshotsViewController.h"
#import "screenshot-Swift.h"


@interface ScreenshotsViewController () < ScreenshotCollectionViewCellDelegate, ScreenshotNotificationCollectionViewCellDelegate, CoreDataPreparationControllerDelegate>


@end

@implementation ScreenshotsViewController

#pragma mark - Life Cycle

- (NSString *)title {
    return @"Screenshots";
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentSizeCategoryDidChange:) name:UIContentSizeCategoryDidChangeNotification object:nil];
        
        _coreDataPreparationController = [[CoreDataPreparationController alloc] init];
        self.coreDataPreparationController.delegate = self;
        
        self.editButtonItem.target = self;
        self.editButtonItem.action = @selector(editButtonAction);
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        [self addNavigationItemLogo];
    }
    return self;
}
 
    - (void)dealloc {
        self.coreDataPreparationController.delegate = nil;
        self.collectionView.delegate = nil;
        self.collectionView.dataSource = nil;
        
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
#pragma mark - Collection View



- (Screenshot *)screenshotAtIndex:(NSInteger)index {
    return [[self screenshotFrc] objectAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
}

- (NSInteger)indexForScreenshot:(Screenshot *)screenshot {
    return [[self screenshotFrc] indexPathForObject:screenshot].item;
}

- (void)scrollToTop {
    if ([self.collectionView numberOfItemsInSection:ScreenshotsSectionImage]) {
        [self.collectionView setContentOffset:CGPointMake(-self.collectionView.contentInset.left, -self.collectionView.contentInset.top)];
    }
}
    
@end
