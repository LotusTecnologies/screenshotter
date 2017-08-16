//
//  FavoritesViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "FavoritesViewController.h"
#import "ProductCollectionViewCell.h"
#import "Geometry.h"
#import "screenshot-Swift.h"

@interface FavoritesViewController () <UICollectionViewDataSource, UICollectionViewDelegate, ProductCollectionViewCellDelegate, FrcDelegateProtocol>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSFetchedResultsController *favoriteFrc;

@end

@implementation FavoritesViewController

#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Favorites";
        [self addNavigationItemLogo];
        
        [DataModel sharedInstance].favoriteFrcDelegate = self;
        self.favoriteFrc = DataModel.sharedInstance.favoriteFrc;
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
        
        [collectionView registerClass:[ProductCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        
        [self.view addSubview:collectionView];
        [collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        [collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
        [collectionView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
        [collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        collectionView;
    });
}

- (void)dealloc {
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    
    [DataModel sharedInstance].favoriteFrcDelegate = nil;
}


#pragma mark - Collection View

- (NSInteger)numberOfCollectionViewColumns {
    return 3;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.favoriteFrc.fetchedObjects.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    Product *product = [self.favoriteFrc objectAtIndexPath:indexPath];
    
    
    ProductCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.delegate = self;
    cell.title = product.productDescription;
    cell.price = product.price;
    cell.imageUrl = product.imageURL;
    cell.favoriteButton.selected = product.isFavorite;
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
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    Product *product = [self.favoriteFrc objectAtIndexPath:indexPath];
    [product setFavoritedToFavorited:!product.isFavorite];
}


#pragma mark - Fetched Results

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
