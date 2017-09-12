//
//  ScreenshotsViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotsViewController.h"
#import "ScreenshotCollectionViewCell.h"
#import "InfoCollectionViewCell.h"
#import "Geometry.h"
#import "screenshot-Swift.h"
#import "HelperView.h"
#import "PermissionsManager.h"
#import "AnalyticsManager.h"
@import PromiseKit;

typedef NS_ENUM(NSUInteger, ScreenshotsSection) {
    ScreenshotsSectionInfo,
    ScreenshotsSectionImages
};

@interface ScreenshotsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, ScreenshotCollectionViewCellDelegate, FrcDelegateProtocol> {
    CGFloat _infoCellBottomInset;
}

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSFetchedResultsController *screenshotFrc;
@property (nonatomic, strong) InfoCollectionViewCell *referencedInfoCell;

@property (nonatomic, strong) HelperView *helperView;
@property (nonatomic, strong) NSDate *lastVisited;

@property (nonatomic) BOOL shouldDisplayInfoCell;

@end

@implementation ScreenshotsViewController

#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        self.title = @"Screenshots";
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        [self addNavigationItemLogo];
        
        [DataModel sharedInstance].screenshotFrcDelegate = self;
        self.screenshotFrc = [DataModel sharedInstance].screenshotFrc;
        
        _infoCellBottomInset = [Geometry padding];
        
        self.shouldDisplayInfoCell = YES; // !!!: DEBUG
        self.referencedInfoCell.type = InfoCollectionViewCellTypeNoFashion; // TODO: set this in the latestScreenshotFrc adds one
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView = ({
        CGFloat p = [Geometry padding];
        
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
        
        [collectionView registerClass:[InfoCollectionViewCell class] forCellWithReuseIdentifier:@"info"];
        [collectionView registerClass:[ScreenshotCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        
        [self.view addSubview:collectionView];
        [collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        [collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
        [collectionView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
        [collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        collectionView;
    });
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor crazeRed];
    [refreshControl addTarget:self action:@selector(refreshControlAction:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:refreshControl];
    
    self.helperView = ({
        CGFloat verticalPadding = 40.f;
        
        HelperView *helperView = [[HelperView alloc] init];
        helperView.translatesAutoresizingMaskIntoConstraints = NO;
        helperView.userInteractionEnabled = NO;
        helperView.titleLabel.text = @"No Screenshots Yet";
        helperView.subtitleLabel.text = @"Add screenshots you want to shop by pressing the power & home buttons at the same time";
        [self.view addSubview:helperView];
        [helperView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:verticalPadding].active = YES;
        [helperView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [helperView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor constant:-verticalPadding].active = YES;
        [helperView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.image = [UIImage imageNamed:@"ScreenshotEmptyListGraphic"];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [helperView.contentView addSubview:imageView];
        [imageView.centerXAnchor constraintEqualToAnchor:helperView.contentView.centerXAnchor].active = YES;
        [imageView.centerYAnchor constraintEqualToAnchor:helperView.contentView.centerYAnchor].active = YES;
        
        helperView;
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self syncHelperViewVisibility];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // TODO: dispatch after to prevent presenting a view controller on dismissed view controller.
    // this function is called before AppDelegate-transitionToViewController:(set window rootVC)
    // Note: turn off photo permissions to enter this path
    // the solution is to create a view controller which deals with the logic and to never change
    // the window, only the underlying view controller.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (![[PermissionsManager sharedPermissionsManager] hasPermissionForType:PermissionTypePhoto]) {
            UIAlertController *alertController = [[PermissionsManager sharedPermissionsManager] deniedAlertControllerForType:PermissionTypePhoto opened:nil];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    });
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
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == ScreenshotsSectionInfo) {
        return self.shouldDisplayInfoCell;
        
    } else if (section == ScreenshotsSectionImages) {
        return self.screenshotFrc.fetchedObjects.count;
        
    } else {
        return 0;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeZero;
    
    if (indexPath.section == ScreenshotsSectionInfo) {
        size.width = floor(collectionView.bounds.size.width - ([Geometry padding] * 2));
        size.height = [self.referencedInfoCell sizeThatFits:size].height + _infoCellBottomInset;
        
    } else if (indexPath.section == ScreenshotsSectionImages) {
        NSInteger columns = [self numberOfCollectionViewColumns];
        
        size.width = floor((collectionView.bounds.size.width - ((columns + 1) * [Geometry padding])) / columns);
        size.height = ceil(size.width * [self screenshotRatio]);
    }
    
    return size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ScreenshotsSectionInfo) {
        InfoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"info" forIndexPath:indexPath];
        cell.contentView.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, _infoCellBottomInset, 0.f);
        cell.type = InfoCollectionViewCellTypeNoFashion;
        [cell.closeButton addTarget:self action:@selector(infoCellCloseButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [cell.continueButton addTarget:self action:@selector(infoCellContinueButtonAction) forControlEvents:UIControlEventTouchUpInside];
        return cell;
        
    } else if (indexPath.section == ScreenshotsSectionImages) {
        Screenshot *screenshot = [self screenshotAtIndex:indexPath.item];
        
        ScreenshotCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
        cell.delegate = self;
        cell.backgroundColor = [UIColor lightGrayColor];
        cell.screenshot = screenshot;
        cell.badgeEnabled = [self badgeEnabledForScreenshot:screenshot];
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
        [self.delegate screenshotsViewController:self didSelectItemAtIndexPath:indexPath];
        
        [AnalyticsManager track:@"Tapped on screenshot"];
    }
}

- (Screenshot *)screenshotAtIndex:(NSInteger)index {
    return [self.screenshotFrc objectAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
}

- (void)scrollTopTop {
    if ([self.collectionView numberOfItemsInSection:ScreenshotsSectionImages]) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    }
}


#pragma mark - Info Cell

- (InfoCollectionViewCell *)referencedInfoCell {
    if (!_referencedInfoCell) {
        _referencedInfoCell = [[InfoCollectionViewCell alloc] init];
    }
    return _referencedInfoCell;
}

- (void)dismissInfoCell {
    self.shouldDisplayInfoCell = NO;
    
    [self.collectionView performBatchUpdates:^{
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:ScreenshotsSectionInfo]];
    } completion:nil];
}

- (void)infoCellCloseButtonAction {
    [self dismissInfoCell];
}

- (void)infoCellContinueButtonAction {
    [self dismissInfoCell];
}


#pragma mark - Screenshot Cell

- (void)screenshotCollectionViewCellDidTapShare:(ScreenshotCollectionViewCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    Screenshot *screenshot = [self screenshotAtIndex:indexPath.item];
    NSArray *items;
    
    if (screenshot.shareLink) {
        items = @[[NSURL URLWithString:screenshot.shareLink]];
        
    } else {
        NSURL *placeholderURL = [NSURL URLWithString:@"https://crazeapp.com/"];
        items = @[[[ScreenshotActivityItemProvider alloc] initWithScreenshot:screenshot placeholderURL:placeholderURL]];
    }
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    activityViewController.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        if (completed) {
            [AnalyticsManager track:@"share completed"];
        } else {
            [AnalyticsManager track:@"share incomplete"];
        }
    };
    
    activityViewController.popoverPresentationController.sourceView = self.view; // so iPads don't crash
    [self presentViewController:activityViewController animated:YES completion:nil];
    
    [AnalyticsManager track:@"Shared screenshot"];
}

- (void)screenshotCollectionViewCellDidTapTrash:(ScreenshotCollectionViewCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    [[self screenshotAtIndex:indexPath.item] setHide];
    
    [AnalyticsManager track:@"Removed screenshot"];
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

- (void)frcOneAddedAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
    [self syncHelperViewVisibility];
}

- (void)frcOneDeletedAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    [self syncHelperViewVisibility];
}

- (void)frcOneUpdatedAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

- (void)frcReloadData {
    [self.collectionView reloadData];
    [self syncHelperViewVisibility];
}


#pragma mark - Helper View

- (void)syncHelperViewVisibility {
    self.helperView.hidden = ([self.collectionView numberOfItemsInSection:ScreenshotsSectionImages] > 0);
    self.collectionView.scrollEnabled = self.helperView.hidden && !self.collectionView.backgroundView;
}


#pragma mark - New Badge

- (BOOL)badgeEnabledForScreenshot:(Screenshot *)screenshot {
    return screenshot.isNew;
}

@end
