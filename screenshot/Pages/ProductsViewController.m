//
//  ProductsViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ProductsViewController.h"
#import "ProductCollectionViewCell.h"
#import "UIColor+Appearance.h"
#import "Geometry.h"
#import "ScreenshotImage.h"

@interface ProductsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIToolbarDelegate, ProductCollectionViewCellDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIToolbar *segmentToolbar;

@property (nonatomic, strong) NSFetchedResultsController *shoppablesFrc;

@end

@implementation ProductsViewController

#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Products";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.shoppablesFrc = [[DataModel sharedInstance] setupShoppableFrcWithScreenshot:self.screenshot];
    
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] init];
    segmentedControl.backgroundColor = [UIColor whiteColor];
    segmentedControl.tintColor = [UIColor crazeRedColor];
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
    
    
    
    [ScreenshotImage screenshot:self.screenshot handler:^(UIImage *image, Screenshot *screenshot) {
        for (NSUInteger i = 0; i < self.shoppablesFrc.fetchedObjects.count; i++) {
            Shoppable *shoppable = [self.shoppablesFrc objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            CGRect imageRect = [shoppable frameWithSize:image.size];
            
            
            [segmentedControl insertSegmentWithImage:[UIImage imageNamed:@"TabBarHeart"] atIndex:i animated:NO];
        }
        
        [segmentedControl sizeToFit];
    }];
    
    
    
    self.segmentToolbar = ({
        UIBarButtonItem *spacerItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.f, 0.f, 0.f, 44.f)];
        toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        toolbar.delegate = self;
        toolbar.items = @[spacerItem, [[UIBarButtonItem alloc] initWithCustomView:segmentedControl], spacerItem];
        
        [self.view addSubview:toolbar];
        [toolbar.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
        [toolbar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [toolbar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        toolbar;
    });
    
    self.collectionView = ({
        CGFloat p = [Geometry padding];
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = p;
        layout.minimumLineSpacing = p;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
        collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.contentInset = UIEdgeInsetsMake(p + self.segmentToolbar.bounds.size.height, p, p, p);
        collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(self.segmentToolbar.bounds.size.height, 0.f, 0.f, 0.f);
        collectionView.backgroundColor = self.view.backgroundColor;
        
        [collectionView registerClass:[ProductCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        
        [self.view insertSubview:collectionView atIndex:0];
        [collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        [collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
        [collectionView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
        [collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        collectionView;
    });
}

- (void)dealloc {
    self.segmentToolbar.delegate = nil;
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    [[DataModel sharedInstance] clearShoppableFrc];
}


#pragma mark - Toolbar

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}


#pragma mark - Segmented Control

- (void)segmentedControlChanged:(UISegmentedControl *)segmentedControl {
    [self reloadCollectionViewForIndex:segmentedControl.selectedSegmentIndex];
}


#pragma mark - Collection View

- (void)reloadCollectionViewForIndex:(NSInteger)index {
    // TODO:
}

- (NSInteger)numberOfCollectionViewColumns {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ProductCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.delegate = self;
    cell.backgroundColor = [UIColor cyanColor];
    cell.title = @"cool product";
    cell.price = @"99";
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger columns = [self numberOfCollectionViewColumns];
    
    CGSize size = CGSizeZero;
    size.width = (collectionView.bounds.size.width - ((columns + 1) * [Geometry padding])) / columns;
    size.height = size.width + [ProductCollectionViewCell labelsHeight];
    return size;
}


#pragma mark - Product Cell

- (void)productCollectionViewCellDidTapFavorite:(ProductCollectionViewCell *)cell {
//    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
}

@end
