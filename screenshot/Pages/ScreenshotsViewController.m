//
//  ScreenshotsViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotsViewController.h"
#import "ScreenshotCollectionViewCell.h"
#import "Geometry.h"
#import "screenshot-Swift.h"
#import "HelperView.h"
#import "PermissionsManager.h"

typedef NS_ENUM(NSUInteger, ScreenshotsSection) {
    ScreenshotsSectionImages
};

@interface ScreenshotsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, ScreenshotCollectionViewCellDelegate, FrcDelegateProtocol>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSFetchedResultsController *screenshotFrc;

@property (nonatomic, strong) ScreenshotsHelperView *helperView;
@property (nonatomic, strong) NSDate *lastVisited;

@property (nonatomic) BOOL shouldDisplayInfoCell;
@property (nonatomic) BOOL didTapOnScreenshot;

@end

@implementation ScreenshotsViewController

#pragma mark - Life Cycle

- (NSString *)title {
    return @"Screenshots";
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        [self addNavigationItemLogo];
        
        [DataModel sharedInstance].screenshotFrcDelegate = self;
        self.screenshotFrc = [DataModel sharedInstance].screenshotFrc;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat p = [Geometry padding];
    
    _collectionView = ({
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = p;
        layout.minimumLineSpacing = p;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
        collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.contentInset = UIEdgeInsetsMake(p, p, p, p);
        collectionView.backgroundColor = self.view.backgroundColor;
        collectionView.alwaysBounceVertical = YES;
        collectionView.scrollEnabled = NO;
        
        [collectionView registerClass:[ScreenshotCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        
        [self.view addSubview:collectionView];
        [collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        [collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
        [collectionView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
        [collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        collectionView;
    });
    
    _refreshControl = ({
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        refreshControl.tintColor = [UIColor crazeRed];
        [refreshControl addTarget:self action:@selector(refreshControlAction:) forControlEvents:UIControlEventValueChanged];
        [self.collectionView addSubview:refreshControl];
        
        // Recenter view
        CGRect rect = refreshControl.subviews[0].frame;
        rect.origin.x = -self.collectionView.contentInset.left / 2.f;
        refreshControl.subviews[0].frame = rect;
        refreshControl;
    });
    
    _helperView = ({
        CGFloat p2 = [Geometry extendedPadding];
        
        ScreenshotsHelperView *helperView = [[ScreenshotsHelperView alloc] init];
        helperView.translatesAutoresizingMaskIntoConstraints = NO;
        helperView.layoutMargins = UIEdgeInsetsMake(p2, p, p2, p);
        [helperView.button addTarget:self action:@selector(helperViewAllowAccessAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:helperView];
        [helperView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
        [helperView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [helperView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor].active = YES;
        [helperView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        helperView;
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self syncHelperViewVisibility];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.didTapOnScreenshot && self.screenshotFrc.fetchedObjects.count == 1 && ![[NSUserDefaults standardUserDefaults] boolForKey:[UserDefaultsKeys shouldPresentPushPermissionsPage]]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[UserDefaultsKeys shouldPresentPushPermissionsPage]];
        
        UIViewController *controller = [[InvokeScreenshotViewController alloc] init];
        [self presentViewController:controller animated:YES completion:nil];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (self.collectionView.backgroundView) {
        [self.collectionView.backgroundView removeFromSuperview];
        self.collectionView.backgroundView = nil;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if (self.view.window) {
        if (self.collectionView.backgroundView) {
            [self.collectionView.backgroundView removeFromSuperview];
            self.collectionView.backgroundView = nil;
        }
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    if (self.view.window) {
        [self syncHelperViewVisibility];
    }
}

- (void)dealloc {
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    
    [DataModel sharedInstance].screenshotFrcDelegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Layout

- (CGFloat)screenshotRatio {
    return 16.f / 9.f;
}

- (void)insertScreenshotHelperView {
    BOOL hasPresented = [[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsKeys.tutorialPresentedScreenshotHelper];
    
    if (!hasPresented && [self.collectionView numberOfItemsInSection:ScreenshotsSectionImages] == 1) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UserDefaultsKeys.tutorialPresentedScreenshotHelper];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
        
        UIView *backgroundView = [[UIView alloc] init];
        self.collectionView.backgroundView = backgroundView;
        
        UIView *contentView = [[UIView alloc] init];
        contentView.translatesAutoresizingMaskIntoConstraints = NO;
        [backgroundView addSubview:contentView];
        [contentView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:layout.minimumLineSpacing].active = YES;
        [contentView.trailingAnchor constraintEqualToAnchor:backgroundView.trailingAnchor constant:-layout.minimumInteritemSpacing].active = YES;
        [contentView.widthAnchor constraintEqualToAnchor:backgroundView.widthAnchor multiplier:.5f constant:-layout.minimumInteritemSpacing * 1.5f].active = YES;
        [contentView.heightAnchor constraintEqualToAnchor:contentView.widthAnchor multiplier:[self screenshotRatio]].active = YES;
        
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.text = @"Ready To Shop";
        titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        titleLabel.minimumScaleFactor = .7f;
        titleLabel.adjustsFontSizeToFitWidth = YES;
        [contentView addSubview:titleLabel];
        [titleLabel.topAnchor constraintEqualToAnchor:contentView.topAnchor].active = YES;
        [titleLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor].active = YES;
        [titleLabel.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor].active = YES;
        
        UILabel *descriptionLabel = [[UILabel alloc] init];
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        descriptionLabel.text = @"Here’s your screenshot!\nTap on it to see the products in the photo.";
        descriptionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        descriptionLabel.numberOfLines = 0;
        [contentView addSubview:descriptionLabel];
        [descriptionLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:[Geometry padding]].active = YES;
        [descriptionLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor].active = YES;
        [descriptionLabel.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor].active = YES;
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TutorialReadyArrow"]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [contentView addSubview:imageView];
        [imageView.topAnchor constraintEqualToAnchor:descriptionLabel.bottomAnchor].active = YES;
        [imageView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor].active = YES;
        [imageView.trailingAnchor constraintLessThanOrEqualToAnchor:contentView.trailingAnchor].active = YES;
        [imageView.bottomAnchor constraintLessThanOrEqualToAnchor:contentView.bottomAnchor].active = YES;
    }
}


#pragma mark - Collection View

- (NSInteger)numberOfCollectionViewColumns {
    return 2;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == ScreenshotsSectionImages) {
        return self.screenshotFrc.fetchedObjects.count;
        
    } else {
        return 0;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeZero;
    
    if (indexPath.section == ScreenshotsSectionImages) {
        NSInteger columns = [self numberOfCollectionViewColumns];
        
        size.width = floor((collectionView.bounds.size.width - ((columns + 1) * [Geometry padding])) / columns);
        size.height = ceil(size.width * [self screenshotRatio]);
    }
    
    return size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ScreenshotsSectionImages) {
        Screenshot *screenshot = [self screenshotAtIndex:indexPath.item];
        
        ScreenshotCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
        cell.delegate = self;
        cell.backgroundColor = [UIColor lightGrayColor];
        cell.screenshot = screenshot;
        cell.badgeEnabled = screenshot.isNew;
        return cell;
        
    } else {
        return nil;
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ScreenshotsSectionImages && indexPath.item == 0) {
        [self insertScreenshotHelperView];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ScreenshotsSectionImages) {
        _didTapOnScreenshot = YES;

        [self.delegate screenshotsViewController:self didSelectItemAtIndexPath:indexPath];
        
        [AnalyticsTrackers.standard track:@"Tapped on screenshot"];
    }
}

- (Screenshot *)screenshotAtIndex:(NSInteger)index {
    return [self.screenshotFrc objectAtIndexPath:[self collectionViewToScreenshotFrcIndexPath:index]];
}

- (void)scrollTopTop {
    if ([self.collectionView numberOfItemsInSection:ScreenshotsSectionImages]) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    }
}


#pragma mark - Screenshot Cell

- (void)screenshotCollectionViewCellDidTapShare:(ScreenshotCollectionViewCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    Screenshot *screenshot = [self screenshotAtIndex:indexPath.item];
    NSString *introductoryText = @"Check out this look on SCREENSHOP!";
    NSArray *items;
    
    if (screenshot.shoppablesCount <= 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Sorry" message:@"We could not find similar items to share." preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
        
    if (screenshot.shareLink) {
        items = @[introductoryText, [NSURL URLWithString:screenshot.shareLink]];
        
    } else {
        ScreenshotActivityItemProvider *screenshotActivityItemProvider = [[ScreenshotActivityItemProvider alloc] initWithScreenshot:screenshot placeholderURL:[NSURL URLWithString:@"https://getscreenshop.com/"]];
        items = @[introductoryText, screenshotActivityItemProvider];
    }
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    activityViewController.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        if (completed) {
            [AnalyticsTrackers.standard track:@"share completed"];
            [AnalyticsTrackers.branch track:@"share completed"];
        } else {
            [AnalyticsTrackers.standard track:@"share incomplete"];
        }
    };
    activityViewController.popoverPresentationController.sourceView = self.view; // so iPads don't crash
    [self presentViewController:activityViewController animated:YES completion:nil];
    
    [AnalyticsTrackers.standard track:@"Shared screenshot"];
}

- (void)screenshotCollectionViewCellDidTapTrash:(ScreenshotCollectionViewCell *)cell {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Screenshot?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        [[self screenshotAtIndex:indexPath.item] setHide];
        
        [AnalyticsTrackers.standard track:@"Removed screenshot"];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - Refresh Control

- (void)refreshControlAction:(UIRefreshControl *)refreshControl {
    if ([refreshControl isRefreshing]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [refreshControl endRefreshing];
        });
    }
}


#pragma mark - Fetch Results Controller

- (void)frc:(NSFetchedResultsController<id<NSFetchRequestResult>> *)frc oneAddedAt:(NSIndexPath *)indexPath {
    if (frc == self.screenshotFrc) {
        [self.collectionView insertItemsAtIndexPaths:@[[self screenshotFrcToCollectionViewIndexPath:indexPath.item]]];
        [self syncHelperViewVisibility];
    }
}

- (void)frc:(NSFetchedResultsController<id<NSFetchRequestResult>> *)frc oneDeletedAt:(NSIndexPath *)indexPath {
    if (frc == self.screenshotFrc) {
        [self.collectionView deleteItemsAtIndexPaths:@[[self screenshotFrcToCollectionViewIndexPath:indexPath.item]]];
        [self syncHelperViewVisibility];
        
        if ([self.collectionView numberOfItemsInSection:ScreenshotsSectionImages] == 0) {
            [self.delegate screenshotsViewControllerDeletedLastScreenshot:self];
        }
    }
}

- (void)frc:(NSFetchedResultsController<id<NSFetchRequestResult>> *)frc oneUpdatedAt:(NSIndexPath *)indexPath {
    if (frc == self.screenshotFrc) {
        [self.collectionView reloadItemsAtIndexPaths:@[[self screenshotFrcToCollectionViewIndexPath:indexPath.item]]];
    }
}

- (void)frcReloadData:(NSFetchedResultsController<id<NSFetchRequestResult>> *)frc {
    if (frc == self.screenshotFrc) {
        [self.collectionView reloadData];
        [self syncHelperViewVisibility];
    }
}

- (NSIndexPath *)collectionViewToScreenshotFrcIndexPath:(NSInteger)index {
    return [NSIndexPath indexPathForItem:index inSection:0];
}

- (NSIndexPath *)screenshotFrcToCollectionViewIndexPath:(NSInteger)index {
    return [NSIndexPath indexPathForItem:index inSection:ScreenshotsSectionImages];
}

- (void)helperViewAllowAccessAction {
    [[PermissionsManager sharedPermissionsManager] requestPermissionForType:PermissionTypePhoto openSettingsIfNeeded:YES response:nil];
}


#pragma mark - Helper View

- (void)syncHelperViewVisibility {
    if ([[PermissionsManager sharedPermissionsManager] hasPermissionForType:PermissionTypePhoto]) {
        if (self.helperView.type != ScreenshotsHelperViewTypeScreenshot) {
            self.helperView.type = ScreenshotsHelperViewTypeScreenshot;
        }
        
    } else {
        if (self.helperView.type != ScreenshotsHelperViewTypePermission) {
            self.helperView.type = ScreenshotsHelperViewTypePermission;
        }
    }
    
    self.helperView.hidden = ([self.collectionView numberOfItemsInSection:ScreenshotsSectionImages] > 0);
    self.collectionView.scrollEnabled = self.helperView.hidden && !self.collectionView.backgroundView;
}

@end
