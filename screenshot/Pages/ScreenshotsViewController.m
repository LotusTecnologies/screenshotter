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
#import "AnalyticsManager.h"

@interface ScreenshotsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, ScreenshotCollectionViewCellDelegate, FrcDelegateProtocol>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSFetchedResultsController *screenshotFrc;
@property (nonatomic, strong) HelperView *helperView;

@end

@implementation ScreenshotsViewController

#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Screenshots";
        [self addNavigationItemLogo];
        
        DataModel *dataModel = [DataModel sharedInstance];
        dataModel.screenshotFrcDelegate = self;
        self.screenshotFrc = dataModel.screenshotFrc;
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
        
        [collectionView registerClass:[ScreenshotCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        
        [self.view addSubview:collectionView];
        [collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        [collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
        [collectionView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
        [collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        collectionView;
    });
    
    self.helperView = ({
        CGFloat verticalPadding = 40.f;
        
        HelperView *helperView = [[HelperView alloc] init];
        helperView.translatesAutoresizingMaskIntoConstraints = NO;
        helperView.userInteractionEnabled = NO;
        helperView.titleLabel.text = @"No Screenshots Yet";
        helperView.subtitleLabel.text = @"Screenshot looks you want to shop by pressing the power & home buttons at the same time";
        [self.view addSubview:helperView];
        [helperView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:verticalPadding].active = YES;
        [helperView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [helperView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor constant:-verticalPadding].active = YES;
        [helperView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.image = [UIImage imageNamed:@"ScreenshotEmptyListHelper"];
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
            UIAlertController *alertController = [[PermissionsManager sharedPermissionsManager] deniedAlertControllerForType:PermissionTypePhoto];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    });
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)dealloc {
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    
    [DataModel sharedInstance].screenshotFrcDelegate = nil;
}


#pragma mark - Collection View

- (NSInteger)numberOfCollectionViewColumns {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.screenshotFrc.fetchedObjects.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger columns = [self numberOfCollectionViewColumns];
    
    CGSize size = CGSizeZero;
    size.width = floor((collectionView.bounds.size.width - ((columns + 1) * [Geometry padding])) / columns);
    size.height = ceil(size.width * (16.f / 9.f));
    return size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    Screenshot *screenshot = [self screenshotAtIndexPath:indexPath];
    
    ScreenshotCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.delegate = self;
    cell.backgroundColor = [UIColor lightGrayColor];
    cell.screenshot = screenshot;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate screenshotsViewController:self didSelectItemAtIndexPath:indexPath];
    
    [AnalyticsManager track:@"Tapped on screenshot"];
}

- (Screenshot *)screenshotAtIndexPath:(NSIndexPath *)indexPath {
    return [self.screenshotFrc objectAtIndexPath:indexPath];
}


#pragma mark - Screenshot Cell

- (void)screenshotCollectionViewCellDidTapShare:(ScreenshotCollectionViewCell *)cell {
//    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Screenshot Sharing" message:@"Coming soon." preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
    
    [AnalyticsManager track:@"Shared screenshot"];
}

- (void)screenshotCollectionViewCellDidTapTrash:(ScreenshotCollectionViewCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    [[self screenshotAtIndexPath:indexPath] setHide];
    
    [AnalyticsManager track:@"Removed screenshot"];
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
    self.helperView.hidden = ([self.collectionView numberOfItemsInSection:0] > 0);
}

@end
