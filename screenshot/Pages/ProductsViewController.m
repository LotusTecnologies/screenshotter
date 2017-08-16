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
#import "ScreenshotImageFetcher.h"
#import "ShoppablesToolbar.h"
#import "ScreenshotDisplayViewController.h"

@interface ProductsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, ProductCollectionViewCellDelegate, FrcDelegateProtocol, ShoppablesToolbarDelegate> {
    BOOL _didViewWillAppear;
}

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) ShoppablesToolbar *shoppablesToolbar;

@property (nonatomic, strong) NSFetchedResultsController *shoppablesFrc;
@property (nonatomic, strong) NSArray<Product *> *products;

@property (nonatomic, copy) UIImage *image;

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
    
    self.shoppablesToolbar = ({
        CGFloat margin = 8.5f; // Anything other then 8 will display horizontal margin
        CGFloat shoppableHeight = 60.f;
        
        ShoppablesToolbar *toolbar = [[ShoppablesToolbar alloc] initWithFrame:CGRectMake(0.f, 0.f, 0.f, margin * 2 + shoppableHeight)];
        toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        toolbar.delegate = self;
        toolbar.layoutMargins = UIEdgeInsetsMake(margin, margin, margin, margin);
        [toolbar insertShoppables:[self shoppables] withScreenshot:self.screenshot];
        [self.view addSubview:toolbar];
        [toolbar.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
        [toolbar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [toolbar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        [toolbar.heightAnchor constraintEqualToConstant:toolbar.bounds.size.height].active = YES;
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
        collectionView.contentInset = UIEdgeInsetsMake(p + self.shoppablesToolbar.bounds.size.height, p, p, p);
        collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(self.shoppablesToolbar.bounds.size.height, 0.f, 0.f, 0.f);
        collectionView.backgroundColor = self.view.backgroundColor;
        
        [collectionView registerClass:[ProductCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        
        [self.view insertSubview:collectionView atIndex:0];
        [collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        [collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
        [collectionView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
        [collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        collectionView;
    });
    
    [ScreenshotImageFetcher screenshot:self.screenshot handler:^(UIImage *image, Screenshot *screenshot) {
        CGFloat buttonSize = 32.f;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0.f, 0.f, buttonSize, buttonSize);
        button.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(displayScreenshotAction) forControlEvents:UIControlEventTouchUpInside];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
        self.image = image;
    }];
    
    [self reloadCollectionViewForIndex:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_didViewWillAppear) {
        [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
    }
    
    _didViewWillAppear = YES;
}

- (void)dealloc {
    self.shoppablesToolbar.delegate = nil;
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    
    [[DataModel sharedInstance] clearShoppableFrc];
    [DataModel sharedInstance].shoppableFrcDelegate = nil;
}


#pragma mark - Screenshot

- (void)setScreenshot:(Screenshot *)screenshot {
    if (_screenshot != screenshot) {
        _screenshot = screenshot;
        
        DataModel *dataModel = [DataModel sharedInstance];
        
        if (screenshot) {
            dataModel.shoppableFrcDelegate = self;
            self.shoppablesFrc = [dataModel setupShoppableFrcWithScreenshot:screenshot];
            
        } else {
            dataModel.shoppableFrcDelegate = nil;
        }
    }
}

- (void)displayScreenshotAction {
    ScreenshotDisplayViewController *viewController = [[ScreenshotDisplayViewController alloc] init];
    viewController.image = self.image;
    [viewController.closeButton addTarget:self action:@selector(dismissScreenshotDisplay) forControlEvents:UIControlEventTouchUpInside];
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)dismissScreenshotDisplay {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Shoppable

- (Shoppable *)shoppableAtIndex:(NSUInteger)index {
    return [self.shoppablesFrc objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
}

- (NSArray<Shoppable *> *)shoppables {
    NSMutableArray *shoppables = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < self.shoppablesFrc.fetchedObjects.count; i++) {
        [shoppables addObject:[self shoppableAtIndex:i]];
    }
    
    return shoppables;
}


#pragma mark - Shoppable

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

- (void)shoppablesToolbar:(ShoppablesToolbar *)toolbar didSelectShoppableAtIndex:(NSUInteger)index {
    [self reloadCollectionViewForIndex:index];
}


#pragma mark - Collection View

- (void)reloadCollectionViewForIndex:(NSInteger)index {
    Shoppable *shoppable = [self shoppableAtIndex:index];
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    self.products = [shoppable.products sortedArrayUsingDescriptors:@[descriptor]];
    
    [self.collectionView reloadData];
    
    if (self.products.count) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    }
}

- (NSInteger)numberOfCollectionViewColumns {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.products.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger columns = [self numberOfCollectionViewColumns];
    
    CGSize size = CGSizeZero;
    size.width = (collectionView.bounds.size.width - ((columns + 1) * [Geometry padding])) / columns;
    size.height = size.width + [ProductCollectionViewCell labelsHeight];
    return size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    Product *product = self.products[indexPath.item];
    
    ProductCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.delegate = self;
    cell.title = product.productDescription;
    cell.price = product.price;
    cell.imageUrl = product.imageURL;
    cell.favoriteButton.selected = product.isFavorite;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate productsViewController:self didSelectItemAtIndexPath:indexPath];
}


#pragma mark - Product Cell

- (void)productCollectionViewCellDidTapFavorite:(ProductCollectionViewCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    Product *product = self.products[indexPath.item];
    [product setFavoritedToFavorited:!product.isFavorite];
}


#pragma mark - Product

- (Product *)productAtIndexPath:(NSIndexPath *)indexPath {
    return self.products[indexPath.item];
}


#pragma mark - Fetched Results Controller

- (void)frcOneAddedAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
}

- (void)frcOneDeletedAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
}

- (void)frcReloadData {
    [self.collectionView reloadData];
}

@end
