//
//  ScreenshotsViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//


#import "ScreenshotsViewController.h"
#import "screenshot-Swift.h"

typedef NS_ENUM(NSUInteger, ScreenshotsSection) {
    ScreenshotsSectionNotification,
    ScreenshotsSectionImage
};

@interface ScreenshotsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, ScreenshotCollectionViewCellDelegate, ScreenshotNotificationCollectionViewCellDelegate, FrcDelegateProtocol, CoreDataPreparationControllerDelegate>

@property (nonatomic, strong) CoreDataPreparationController *coreDataPreparationController;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSFetchedResultsController *screenshotFrc;
@property (nonatomic, strong) ScreenshotsHelperView *helperView;

@property (nonatomic, strong) ScreenshotsDeleteButton *deleteButton;
@property (nonatomic, strong) NSMutableArray<NSManagedObjectID *> *deleteScreenshotObjectIDs;

@property (nonatomic, strong) NSDate *lastVisited;

@property (nonatomic, copy) NSString *notificationCellAssetId;

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIEdgeInsets shadowInsets = [ScreenshotCollectionViewCell shadowInsets];
    CGFloat p = [Geometry padding];
    CGPoint minimumSpacing = CGPointMake(p - shadowInsets.left - shadowInsets.right, p - shadowInsets.top - shadowInsets.bottom);
    
    _collectionView = ({
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = minimumSpacing.x;
        layout.minimumLineSpacing = minimumSpacing.y;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
        collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.contentInset = UIEdgeInsetsMake(minimumSpacing.y, minimumSpacing.x, minimumSpacing.y, minimumSpacing.x);
        collectionView.backgroundColor = self.view.backgroundColor;
        collectionView.alwaysBounceVertical = YES;
        collectionView.scrollEnabled = NO;
        collectionView.allowsMultipleSelection = YES;
        
        [collectionView registerClass:[ScreenshotNotificationCollectionViewCell class] forCellWithReuseIdentifier:@"notification"];
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
        CGFloat verPadding = [Geometry extendedPadding];
        CGFloat horPadding = [Geometry padding];
        
        ScreenshotsHelperView *helperView = [[ScreenshotsHelperView alloc] init];
        helperView.translatesAutoresizingMaskIntoConstraints = NO;
        helperView.layoutMargins = UIEdgeInsetsMake(verPadding, horPadding, verPadding, horPadding);
        [helperView.button addTarget:self action:@selector(helperViewAllowAccessAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:helperView];
        [helperView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
        [helperView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [helperView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor].active = YES;
        [helperView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        helperView;
    });
    
    [self.coreDataPreparationController viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self syncHelperViewVisibility];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self removeScreenshotHelperView];
    
    if ([self isEditing]) {
        // Incase the app somehow changed view controllers while editing, cancel it.
        [self setEditing:NO animated:animated];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if (self.view.window) {
        [self removeScreenshotHelperView];
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    if (self.view.window) {
        [self syncHelperViewVisibility];
    }
}

- (void)contentSizeCategoryDidChange:(NSNotification *)notification {
    if (self.view.window && [self.collectionView numberOfItemsInSection:ScreenshotsSectionNotification] > 0) {
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:ScreenshotsSectionNotification]]];
    }
}

- (void)dealloc {
    self.coreDataPreparationController.delegate = nil;
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    
    [DataModel sharedInstance].screenshotFrcDelegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Layout

- (void)insertScreenshotHelperView {
    BOOL hasPresented = [[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsKeys.onboardingPresentedScreenshotHelper];
    
    if (!hasPresented && [self.collectionView numberOfItemsInSection:ScreenshotsSectionImage] == 1) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UserDefaultsKeys.onboardingPresentedScreenshotHelper];
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
        [contentView.heightAnchor constraintEqualToAnchor:contentView.widthAnchor multiplier:[Screenshot ratio].height].active = YES;
        
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.text = @"Ready To Shop";
        titleLabel.font = [UIFont systemFontOfSize:22.f weight:UIFontWeightSemibold];
        titleLabel.numberOfLines = 0;
        [contentView addSubview:titleLabel];
        [titleLabel.topAnchor constraintEqualToAnchor:contentView.topAnchor].active = YES;
        [titleLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor].active = YES;
        [titleLabel.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor].active = YES;
        
        UILabel *descriptionLabel = [[UILabel alloc] init];
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        descriptionLabel.text = @"Here’s your screenshot!\nTap on it to see the products in the photo.";
        descriptionLabel.font = [UIFont systemFontOfSize:22.f weight:UIFontWeightLight];
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

- (void)removeScreenshotHelperView {
    if (self.collectionView.backgroundView) {
        [self.collectionView.backgroundView removeFromSuperview];
        self.collectionView.backgroundView = nil;
    }
}


#pragma mark - Editing

- (void)editButtonAction {
    BOOL isEditing = ![self isEditing];
    
    if (!isEditing) {
        // Needs to be before setEditing
        [self deselectDeletedScreenshots];
    }
    
    [self setEditing:isEditing animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (self.tabBarController && editing) {
        CGFloat bottom = 0.f;
        
        if (@available(iOS 11.0, *)) {
            bottom = [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom / 2.f;
        }
        
        self.deleteButton.alpha = 0.f;
        self.deleteButton.contentEdgeInsets = UIEdgeInsetsMake(0.f, 0.f, bottom, 0.f);
        [self.tabBarController.tabBar addSubview:self.deleteButton];
        [self.deleteButton.topAnchor constraintEqualToAnchor:self.tabBarController.tabBar.topAnchor].active = YES;
        [self.deleteButton.leadingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.leadingAnchor].active = YES;
        [self.deleteButton.bottomAnchor constraintEqualToAnchor:self.tabBarController.tabBar.bottomAnchor].active = YES;
        [self.deleteButton.trailingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.trailingAnchor].active = YES;
    }
    
    dispatch_block_t removeDeleteButton = ^{
        if (self.tabBarController && !editing) {
            [self.deleteButton removeFromSuperview];
            [self updateDeleteButtonCount];
        }
    };
    
    dispatch_block_t cellEditing = ^{
        for (NSIndexPath *indexPath in self.collectionView.indexPathsForVisibleItems) {
            ScreenshotCollectionViewCell *cell = (ScreenshotCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            
            if ([cell isKindOfClass:[ScreenshotCollectionViewCell class]]) {
                cell.isEditing = editing;
                [self syncScreenshotCollectionViewCellSelectedState:cell];
            }
        }
        
        if ([self hasNewScreenshot]) {
            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:ScreenshotsSectionNotification]];
        }
        
        self.deleteButton.alpha = editing;
    };
    
    if (animated) {
        [UIView animateWithDuration:[Constants defaultAnimationDuration] animations:^{
            cellEditing();
        } completion:^(BOOL finished) {
            removeDeleteButton();
        }];
    }
    else {
        cellEditing();
        removeDeleteButton();
    }
    
    self.navigationItem.rightBarButtonItem.enabled = !editing;
    
    if (editing) {
        self.editButtonItem.title = @"Cancel";
        
        self.deleteScreenshotObjectIDs = [NSMutableArray array];
    }
}

- (void)deselectDeletedScreenshots {
    // TODO: call this in cleanup from frc callback
    
    // Deselect all cells
    [self.collectionView selectItemAtIndexPath:nil animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    
    self.deleteScreenshotObjectIDs = nil;
}

- (ScreenshotsDeleteButton *)deleteButton {
    if (!_deleteButton) {
        ScreenshotsDeleteButton *deleteButton = [ScreenshotsDeleteButton buttonWithType:UIButtonTypeCustom];
        deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
        [deleteButton addTarget:self action:@selector(deleteButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _deleteButton = deleteButton;
    }
    return _deleteButton;
}

- (void)updateDeleteButtonCount {
    self.deleteButton.deleteCount = self.collectionView.indexPathsForSelectedItems.count;
}

- (void)deleteButtonAction {
    [self setEditing:NO animated:YES];
    self.editButtonItem.enabled = NO;
    
    // TODO: make sure the screenshots enter a disabled state and cant be deleted a second time if the database is taking long
    
//    if (self.deleteScreenshotObjectIDs.count > 0) {
//        [[DataModel sharedInstance] hideWithScreenshotOIDArray:self.deleteScreenshotObjectIDs];
//    }
}


#pragma mark - Collection View Sections

- (NSUInteger)newScreenshotsCount {
    return [[AccumulatorModel sharedInstance] getNewScreenshotsCount];
}

- (BOOL)hasNewScreenshot {
    return [self newScreenshotsCount] > 0;
}

- (ScreenshotNotificationCollectionViewCellContentText)notificationContentText {
    NSUInteger count = [self newScreenshotsCount];
    
    if (count == 1) {
        return ScreenshotNotificationCollectionViewCellContentTextImportSingleScreenshot;
        
    } else if (count > 1) {
        return ScreenshotNotificationCollectionViewCellContentTextImportMultipleScreenshots;
        
    } else {
        return ScreenshotNotificationCollectionViewCellContentTextNone;
    }
}


#pragma mark - Collection View

- (NSInteger)numberOfCollectionViewImageColumns {
    return 2;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == ScreenshotsSectionNotification) {
        return [self canDisplayNotificationCell];
        
    } else if (section == ScreenshotsSectionImage) {
        return self.screenshotFrc.fetchedObjects.count;
        
    } else {
        return 0;
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    
    if (section == ScreenshotsSectionNotification && [self hasNewScreenshot]) {
        insets.bottom = ((UICollectionViewFlowLayout *)collectionView.collectionViewLayout).minimumLineSpacing;
    }
    
    return insets;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeZero;
    UIEdgeInsets shadowInsets = [ScreenshotNotificationCollectionViewCell shadowInsets];
    CGFloat padding = [Geometry padding] - shadowInsets.left - shadowInsets.right;
    
    if (indexPath.section == ScreenshotsSectionNotification) {
        size.width = floor(collectionView.bounds.size.width - (padding * 2));
        size.height = [ScreenshotNotificationCollectionViewCell heightWithCellWidth:size.width contentText:[self notificationContentText] contentType:ScreenshotNotificationCollectionViewCellContentTypeLabelWithButtons];
    }
    else if (indexPath.section == ScreenshotsSectionImage) {
        NSInteger columns = [self numberOfCollectionViewImageColumns];
        
        size.width = floor((collectionView.bounds.size.width - (padding * (columns + 1))) / columns);
        size.height = ceil(size.width * [Screenshot ratio].height);
    }
    
    return size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ScreenshotsSectionNotification) {
        ScreenshotNotificationCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"notification" forIndexPath:indexPath];
        cell.delegate = self;
        cell.contentView.backgroundColor = collectionView.backgroundColor;
        cell.contentText = [self notificationContentText];
        [cell setContentType:ScreenshotNotificationCollectionViewCellContentTypeLabelWithButtons];
        cell.iconImage = nil;
        
        [[AssetSyncModel sharedInstance] imageWithAssetId:self.notificationCellAssetId callback:^(UIImage *image, NSDictionary *info) {
            cell.iconImage = image ?: [UIImage imageNamed:@"NotificationSnapshot"];
        }];
        
        return cell;
    }
    else if (indexPath.section == ScreenshotsSectionImage) {
        Screenshot *screenshot = [self screenshotAtIndex:indexPath.item];
        
        ScreenshotCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
        cell.delegate = self;
        cell.contentView.backgroundColor = collectionView.backgroundColor;
        cell.screenshot = screenshot;
        cell.isBadgeEnabled = screenshot.isNew;
        cell.isEditing = [self isEditing];
        [self syncScreenshotCollectionViewCellSelectedState:cell];
        return cell;
    }
    else {
        return nil;
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ScreenshotsSectionImage) {
        if (indexPath.item == 0) {
            [self insertScreenshotHelperView];
        }
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ScreenshotsSectionNotification && [self isEditing]) {
        return NO;
    }
    else {
        return YES;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ScreenshotsSectionImage) {
        Screenshot *screenshot = [self screenshotAtIndex:indexPath.item];
        
        if ([self isEditing]) {
            [self updateDeleteButtonCount];
            [self.deleteScreenshotObjectIDs addObject:screenshot.objectID];
        }
        else {
            if (self.deleteScreenshotObjectIDs.count > 0 && [self.deleteScreenshotObjectIDs containsObject:screenshot.objectID]) {
                return;
            }
            
            [collectionView deselectItemAtIndexPath:indexPath animated:NO];
            [self.delegate screenshotsViewController:self didSelectItemAtIndexPath:indexPath];
            
            if (screenshot.uploadedImageURL) {
                [AnalyticsTrackers.standard track:@"Tapped on screenshot" properties:@{@"screenshot": screenshot.uploadedImageURL}];
            }
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ScreenshotsSectionImage && [self isEditing]) {
        Screenshot *screenshot = [self screenshotAtIndex:indexPath.item];
        
        [self updateDeleteButtonCount];
        [self.deleteScreenshotObjectIDs removeObject:screenshot.objectID];
    }
}

- (Screenshot *)screenshotAtIndex:(NSInteger)index {
    return [self.screenshotFrc objectAtIndexPath:[self collectionViewToScreenshotFrcIndexPath:index]];
}

- (NSInteger)indexForScreenshot:(Screenshot *)screenshot {
    return [self.screenshotFrc indexPathForObject:screenshot].item;
}

- (void)scrollToTop {
    if ([self.collectionView numberOfItemsInSection:ScreenshotsSectionImage]) {
        [self.collectionView setContentOffset:CGPointMake(-self.collectionView.contentInset.left, -self.collectionView.contentInset.top)];
    }
}


#pragma mark - Notification Cell

- (BOOL)canDisplayNotificationCell {
    return [self hasNewScreenshot] && ![self isEditing];
}

- (void)screenshotNotificationCollectionViewCellDidTapReject:(ScreenshotNotificationCollectionViewCell *)cell {
    NSUInteger screenshotsCount = [self newScreenshotsCount];
    [[AccumulatorModel sharedInstance] resetNewScreenshotsCount];
    
    [self dismissNotificationCell];
    [self syncHelperViewVisibility];
    
    [AnalyticsTrackers.standard track:@"Screenshot notification cancelled" properties:@{@"Screenshot count": @(screenshotsCount)}];
}

- (void)screenshotNotificationCollectionViewCellDidTapConfirm:(ScreenshotNotificationCollectionViewCell *)cell {
    NSUInteger screenshotsCount = [self newScreenshotsCount];
    [[AccumulatorModel sharedInstance] resetNewScreenshotsCount];
    
    if (cell.contentText == ScreenshotNotificationCollectionViewCellContentTextImportSingleScreenshot) {
        [[AssetSyncModel sharedInstance] refetchLastScreenshot];
        
    } else if (cell.contentText == ScreenshotNotificationCollectionViewCellContentTextImportMultipleScreenshots) {
        [self.delegate screenshotsViewControllerWantsToPresentPicker:self];
    }
    
    [self dismissNotificationCell];
    [self syncHelperViewVisibility];
    
    [AnalyticsTrackers.standard track:@"Screenshot notification accepted" properties:@{@"Screenshot count": @(screenshotsCount)}];
}

- (void)presentNotificationCellWithAssetId:(NSString *)assetId {
    if ([self canDisplayNotificationCell]) {
        self.notificationCellAssetId = assetId;
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:ScreenshotsSectionNotification];
        
        if ([self.collectionView numberOfItemsInSection:ScreenshotsSectionNotification] == 0) {
            [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
            
        } else {
            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        }
        
        [self syncHelperViewVisibility];
    }
}

- (void)dismissNotificationCell {
    if ([self.collectionView numberOfItemsInSection:ScreenshotsSectionNotification] > 0) {
        [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:ScreenshotsSectionNotification]]];
    }
}


#pragma mark - Screenshot Cell

- (void)screenshotCollectionViewCellDidTapShare:(ScreenshotCollectionViewCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    Screenshot *screenshot = [self screenshotAtIndex:indexPath.item];
    NSString *introductoryText = @"Check out this look on SCREENSHOP!";
    NSArray *items;
    
    // iOS 11.1 has a bug where copying to clipboard while sharing doesn't put a space between activity items.
    NSString *space = @" ";
    
    if (screenshot.shoppablesCount <= 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Sorry" message:@"We could not find similar items to share." preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
        
    if (screenshot.shareLink) {
        items = @[introductoryText, space, [NSURL URLWithString:screenshot.shareLink]];
        
    } else {
        ScreenshotActivityItemProvider *screenshotActivityItemProvider = [[ScreenshotActivityItemProvider alloc] initWithScreenshot:screenshot placeholderURL:[NSURL URLWithString:@"https://getscreenshop.com/"]];
        items = @[introductoryText, space, screenshotActivityItemProvider];
    }
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    activityViewController.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        if (completed) {
            [AnalyticsTrackers.standard track:@"Share completed" properties:nil];
            [AnalyticsTrackers.branch track:@"Share completed" properties:nil];
            
        } else {
            [AnalyticsTrackers.standard track:@"Share incomplete" properties:nil];
        }
    };
    activityViewController.popoverPresentationController.sourceView = self.view; // so iPads don't crash
    [self presentViewController:activityViewController animated:YES completion:nil];
    
    [AnalyticsTrackers.standard track:@"Shared screenshot" properties:nil];
}

- (void)screenshotCollectionViewCellDidTapDelete:(ScreenshotCollectionViewCell *)cell {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Screenshot?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        
        if ([self.collectionView numberOfItemsInSection:ScreenshotsSectionImage] > indexPath.row) {
            [[self screenshotAtIndex:indexPath.item] setHide];
            [self removeScreenshotHelperView];
            
            [UIView animateWithDuration:[Constants defaultAnimationDuration] animations:^{
                [cell _setSelectedState:2];
            }];
            
            [AnalyticsTrackers.standard track:@"Removed screenshot" properties:nil];
        }
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)syncScreenshotCollectionViewCellSelectedState:(ScreenshotCollectionViewCell *)cell {
    if ([self isEditing]) {
        [cell _setSelectedState:1];
    }
    else if ([cell isSelected] && self.deleteScreenshotObjectIDs.count > 0) {
        [cell _setSelectedState:2];
    }
    else {
        [cell _setSelectedState:0];
    }
}


#pragma mark - Refresh Control

- (void)refreshControlAction:(UIRefreshControl *)refreshControl {
    if ([refreshControl isRefreshing]) {
        // This is for show.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [refreshControl endRefreshing];
        });
    }
}


#pragma mark - Core Data Preparation

- (void)coreDataPreparationControllerSetup:(CoreDataPreparationController *)controller {
    [DataModel sharedInstance].screenshotFrcDelegate = self;
    self.screenshotFrc = [DataModel sharedInstance].screenshotFrc;
    
    if ([DataModel sharedInstance].isCoreDataStackReady) {
        [self.collectionView reloadData];
        [self syncHelperViewVisibility];
    }
}

- (void)coreDataPreparationController:(CoreDataPreparationController *)controller presentLoader:(UIView *)loader {
    loader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:loader];
    [loader.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [loader.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [loader.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [loader.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
}

- (void)coreDataPreparationController:(CoreDataPreparationController *)controller dismissLoader:(UIView *)loader {
    [loader removeFromSuperview];
}


#pragma mark - Fetch Results Controller

- (void)frc:(NSFetchedResultsController<id<NSFetchRequestResult>> *)frc oneAddedAt:(NSIndexPath *)indexPath {
    if (frc == self.screenshotFrc) {
        NSIndexPath *collectionViewIndexPath = [self screenshotFrcToCollectionViewIndexPath:indexPath.item];
        
        [self.collectionView insertItemsAtIndexPaths:@[collectionViewIndexPath]];
        [self.collectionView scrollToItemAtIndexPath:collectionViewIndexPath atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        [self syncHelperViewVisibility];
    }
}

- (void)frc:(NSFetchedResultsController<id<NSFetchRequestResult>> *)frc oneDeletedAt:(NSIndexPath *)indexPath {
    if (frc == self.screenshotFrc) {
        [self.collectionView deleteItemsAtIndexPaths:@[[self screenshotFrcToCollectionViewIndexPath:indexPath.item]]];
        [self syncHelperViewVisibility];
        
        if ([self.collectionView numberOfItemsInSection:ScreenshotsSectionImage] == 0) {
            [self.delegate screenshotsViewControllerDeletedLastScreenshot:self];
        }
    }
}

- (void)frc:(NSFetchedResultsController<id<NSFetchRequestResult>> *)frc oneUpdatedAt:(NSIndexPath *)indexPath {
    if (frc == self.screenshotFrc) {
        [self.collectionView reloadItemsAtIndexPaths:@[[self screenshotFrcToCollectionViewIndexPath:indexPath.item]]];
    }
}

- (void)frc:(NSFetchedResultsController<id<NSFetchRequestResult>> *)frc oneMovedTo:(NSIndexPath *)indexPath {
    if (frc == self.screenshotFrc) {
        NSIndexPath *collectionViewIndexPath = [self screenshotFrcToCollectionViewIndexPath:indexPath.item];
        
        [self.collectionView reloadData];
        [self.collectionView scrollToItemAtIndexPath:collectionViewIndexPath atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
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
    return [NSIndexPath indexPathForItem:index inSection:ScreenshotsSectionImage];
}

- (void)helperViewAllowAccessAction {
    [[PermissionsManager shared] _requestPhotoPermissionWithOpenSettingsIfNeeded:YES response:^(BOOL granted) {
        [self syncHelperViewVisibility];
    }];
}


#pragma mark - Helper View

- (void)syncHelperViewVisibility {
    if ([[PermissionsManager shared] _hasPhotoPermission]) {
        if (self.helperView.type != ScreenshotsHelperViewTypeScreenshot) {
            self.helperView.type = ScreenshotsHelperViewTypeScreenshot;
        }
        
    } else {
        if (self.helperView.type != ScreenshotsHelperViewTypePermission) {
            self.helperView.type = ScreenshotsHelperViewTypePermission;
        }
    }
    
    BOOL hasScreenshots = [self.collectionView numberOfItemsInSection:ScreenshotsSectionImage] > 0;
    
    self.helperView.hidden = (hasScreenshots || [self.collectionView numberOfItemsInSection:ScreenshotsSectionNotification] > 0);
    self.collectionView.scrollEnabled = self.helperView.hidden && !self.collectionView.backgroundView;
    self.editButtonItem.enabled = hasScreenshots;
}

@end
