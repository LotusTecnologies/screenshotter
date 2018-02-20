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




#pragma mark - Editing


#pragma mark - Collection View Sections


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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeZero;
    
    if (indexPath.section == ScreenshotsSectionProduct) {
        size.width = collectionView.bounds.size.width - collectionView.contentInset.left - collectionView.contentInset.right;
        size.height = 138;
    }
    else {
        CGPoint minimumSpacing = [self collectionViewInteritemOffset];
        
        if (indexPath.section == ScreenshotsSectionNotification) {
            size.width = floor(collectionView.bounds.size.width - (minimumSpacing.x * 2));
            size.height = [ScreenshotNotificationCollectionViewCell heightWithCellWidth:size.width contentText:[self notificationContentText] contentType:ScreenshotNotificationCollectionViewCellContentTypeLabelWithButtons];
        }
        else if (indexPath.section == ScreenshotsSectionImage) {
            NSInteger columns = [self numberOfCollectionViewImageColumns];
            
            size.width = floor((collectionView.bounds.size.width - (minimumSpacing.x * (columns + 1))) / columns);
            size.height = ceil(size.width * [Screenshot ratio].height);
        }
    }
    
    return size;
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
            [self.deleteScreenshotObjectIDs addObject:screenshot.objectID];
            [self updateDeleteButtonCount];
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
        [self.deleteScreenshotObjectIDs removeObject:screenshot.objectID];
        [self updateDeleteButtonCount];
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

- (CGPoint)collectionViewInteritemOffset {
    UIEdgeInsets shadowInsets = [ScreenshotCollectionViewCell shadowInsets];
    CGFloat x = [Geometry padding] - shadowInsets.left - shadowInsets.right;
    CGFloat y = [Geometry padding] - shadowInsets.top - shadowInsets.bottom;
    return CGPointMake(x, y);
}


#pragma mark - Notification Cell



@end
