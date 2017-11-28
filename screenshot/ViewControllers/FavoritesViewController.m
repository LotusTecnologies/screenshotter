//
//  FavoritesViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "FavoritesViewController.h"
#import "ProductCollectionViewCell.h"

#import "screenshot-Swift.h"
#import "WebViewController.h"


#import <FBSDKCoreKit/FBSDKCoreKit.h>
@import Analytics;

@interface FavoritesViewController () <UICollectionViewDataSource, UICollectionViewDelegate, ProductCollectionViewCellDelegate> {
    BOOL _didViewWillAppear;
    BOOL _needsReloadData;
}

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSFetchedResultsController *favoriteFrc;
@property (nonatomic, strong) HelperView *helperView;
@property (nonatomic, strong) NSMutableArray<Product *> *unfavoriteArray;

@end

@implementation FavoritesViewController

#pragma mark - Life Cycle

- (NSString *)title {
    return @"Favorites";
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        [self addNavigationItemLogo];
        
        self.favoriteFrc = [DataModel sharedInstance].favoriteFrc;
        self.unfavoriteArray = [NSMutableArray array];
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
    
    self.helperView = ({
        CGFloat verPadding = [Geometry extendedPadding];
        CGFloat horPadding = [Geometry padding];
        
        HelperView *helperView = [[HelperView alloc] init];
        helperView.translatesAutoresizingMaskIntoConstraints = NO;
        helperView.layoutMargins = UIEdgeInsetsMake(verPadding, horPadding, verPadding, horPadding);
        helperView.titleLabel.text = @"No Favorites";
        helperView.subtitleLabel.text = @"Tap the heart icon on products to add them to your favorites";
        helperView.contentImage = [UIImage imageNamed:@"FavoriteEmptyListGraphic"];
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
    
    if (_didViewWillAppear || _needsReloadData) {
        _needsReloadData = NO;
        [self.collectionView reloadData];
    }
    
    _didViewWillAppear = YES;
    
    [self syncHelperViewVisibility];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self removeUnfavorited];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if (self.view.window) {
        [self removeUnfavorited];
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    if (self.view.window) {
        if (_needsReloadData) {
            _needsReloadData = NO;
            [self.collectionView reloadData];
        }
    }
}

- (void)dealloc {
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Collection View

- (NSInteger)numberOfCollectionViewColumns {
    return 3;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.favoriteFrc.fetchedObjects.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger columns = [self numberOfCollectionViewColumns];
    
    CGSize size = CGSizeZero;
    size.width = (collectionView.bounds.size.width - ((columns + 1) * [Geometry padding])) / columns;
    size.height = size.width + [ProductCollectionViewCell labelsHeight];
    return size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    Product *product = [self.favoriteFrc objectAtIndexPath:indexPath];
    
    ProductCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.delegate = self;
    cell.contentView.backgroundColor = collectionView.backgroundColor;
    cell.title = product.productDescription;
    cell.price = product.price;
    cell.imageUrl = product.imageURL;
    cell.favoriteButton.selected = product.isFavorite;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (![self.navigationController.topViewController isKindOfClass:[WebViewController class]]) {
        Product *product = [self.favoriteFrc objectAtIndexPath:indexPath];
        
        WebViewController *webViewController = [[WebViewController alloc] init];
        [webViewController addNavigationItemLogo];
        webViewController.hidesBottomBarWhenPushed = YES;
        webViewController.url = [NSURL URLWithString:product.offer];
        
        [self.navigationController pushViewController:webViewController animated:YES];
        
        [AnalyticsTrackers.standard track:@"Tapped on product" properties:@{@"merchant": product.merchant,
                                                                            @"brand": product.brand,
                                                                            @"url": product.offer,
                                                                            @"imageUrl": product.imageURL,
                                                                            @"sale": @([product isSale]),
                                                                            @"page": @"Favorites"
                                                                            }];
        [AnalyticsTrackers.branch track:@"Tapped on product"];
        
        [FBSDKAppEvents logEvent:FBSDKAppEventNameViewedContent parameters:@{FBSDKAppEventParameterNameContentID: product.imageURL}];
    }
}


#pragma mark - Product Cell

- (void)productCollectionViewCellDidTapFavorite:(ProductCollectionViewCell *)cell {
    BOOL isFavorited = [cell.favoriteButton isSelected];
    
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    Product *product = [self.favoriteFrc objectAtIndexPath:indexPath];
    
    if (isFavorited) {
        [self.unfavoriteArray removeObject:product];
        
    } else {
        [self.unfavoriteArray addObject:product];
    }
    
    NSString *favoriteString = isFavorited ? @"Product favorited" : @"Product unfavorited";
    
    [AnalyticsTrackers.standard track:favoriteString properties:@{@"merchant": product.merchant,
                                                                  @"brand": product.brand,
                                                                  @"url": product.offer,
                                                                  @"imageUrl": product.imageURL,
                                                                  @"page": @"Favorites"
                                                                  }];
    
    NSString *value = isFavorited ? FBSDKAppEventParameterValueYes : FBSDKAppEventParameterValueNo;
    [FBSDKAppEvents logEvent:FBSDKAppEventNameAddedToWishlist parameters:@{FBSDKAppEventParameterNameSuccess: value}];
}


#pragma mark - Favorites

- (void)removeUnfavorited {
    if (self.unfavoriteArray.count) {
        [[DataModel sharedInstance] unfavoriteWithFavoriteArray:self.unfavoriteArray];
        [self.unfavoriteArray removeAllObjects];
        _needsReloadData = YES;
    }
}


#pragma mark - Helper View

- (void)syncHelperViewVisibility {
    self.helperView.hidden = ([self.collectionView numberOfItemsInSection:0] > 0);
}

@end
