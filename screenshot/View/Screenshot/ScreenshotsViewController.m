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

@property (nonatomic, strong) CoreDataPreparationController *coreDataPreparationController;

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
    [self setupViews];
    
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
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark - Collection View


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 3;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == ScreenshotsSectionProduct) {
        return [self.productsBarController hasProducts] ? 1 : 0;
    }
    else if (section == ScreenshotsSectionNotification) {
        return [self canDisplayNotificationCell];
    }
    else if (section == ScreenshotsSectionImage) {
        return [self screenshotFrc].fetchedObjectsCount;
    }
    else {
        return 0;
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    
    BOOL isShowingNotification = section == ScreenshotsSectionNotification && [self hasNewScreenshot];
    BOOL isShowingImage = section == ScreenshotsSectionImage;
    
    if (isShowingNotification || isShowingImage) {
        CGPoint minimumSpacing = [self collectionViewInteritemOffset];
        
        insets.top = minimumSpacing.y;
        insets.left = minimumSpacing.x;
        insets.right = minimumSpacing.x;
    }
    
    return insets;
}


- (void)setupScreenshotProductBarCollectionViewCell:(ScreenshotProductBarCollectionViewCell *)cell collectionView:(UICollectionView *)collectionView forItemAtIndexPath:(NSIndexPath *)indexPath {
    self.productsBarController.collectionView = cell.collectionView;
}
    
-(void) setupScreenshotNotificationCollectionViewCell:(ScreenshotNotificationCollectionViewCell*)cell collectionView:(UICollectionView*) collectionView forItemAtIndexPath:(NSIndexPath*) indexPath{
    cell.delegate = self;
    cell.contentView.backgroundColor = collectionView.backgroundColor;
    cell.contentText = [self notificationContentText];
    [cell setContentType:ScreenshotNotificationCollectionViewCellContentTypeLabelWithButtons];
    cell.iconImage = nil;
    
    [[AssetSyncModel sharedInstance] imageWithAssetId:self.notificationCellAssetId callback:^(UIImage *image, NSDictionary *info) {
        cell.iconImage = image ?: [UIImage imageNamed:@"NotificationSnapshot"];
    }];
    
}
    
-(void) setupScreenshotCollectionViewCell:(ScreenshotCollectionViewCell*)cell collectionView:(UICollectionView*) collectionView forItemAtIndexPath:(NSIndexPath*) indexPath{
    Screenshot *screenshot = [self screenshotAtIndex:indexPath.item];
    cell.delegate = self;
    cell.contentView.backgroundColor = collectionView.backgroundColor;
    cell.screenshot = screenshot;
    cell.isBadgeEnabled = screenshot.isNew;
    cell.isEditing = [self isEditing];
    [self syncScreenshotCollectionViewCellSelectedState:cell];
}
    
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ScreenshotsSectionProduct) {
        ScreenshotProductBarCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"product" forIndexPath:indexPath];
        [self setupScreenshotProductBarCollectionViewCell:cell collectionView:collectionView forItemAtIndexPath:indexPath];
        return cell;
    }
    else if (indexPath.section == ScreenshotsSectionNotification) {
        ScreenshotNotificationCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"notification" forIndexPath:indexPath];
        [self setupScreenshotNotificationCollectionViewCell:cell collectionView:collectionView forItemAtIndexPath:indexPath];
        return cell;
    }
    else if (indexPath.section == ScreenshotsSectionImage) {
        ScreenshotCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
        [self setupScreenshotCollectionViewCell:cell collectionView:collectionView forItemAtIndexPath:indexPath];
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
