//
//  ProductsViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ProductsViewController.h"
#import "ProductCollectionViewCell.h"
#import "Geometry.h"
#import "ShoppablesToolbar.h"
#import "ScreenshotDisplayNavigationController.h"
#import "WebViewController.h"
#import "AnalyticsManager.h"
#import "TutorialProductsPageViewController.h"
#import "TransitioningController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

typedef NS_ENUM(NSUInteger, ShoppableSortType) {
    ShoppableSortTypeSimilar,
    ShoppableSortTypePrice,
    ShoppableSortTypeBrands
};

@interface ProductsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, ProductCollectionViewCellDelegate, FrcDelegateProtocol, ShoppablesToolbarDelegate> {
    BOOL _didViewDidAppear;
}

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) ShoppablesToolbar *shoppablesToolbar;

@property (nonatomic, strong) NSFetchedResultsController *shoppablesFrc;
@property (nonatomic, strong) NSArray<Product *> *products;
@property (nonatomic, strong) NSDictionary<NSNumber *, NSString *> *shoppableSortTitles;
@property (nonatomic) ShoppableSortType currentSortType;

@property (nonatomic, copy) UIImage *image;

@property (nonatomic, strong) TransitioningController *transitioningController;

@end

@interface ProductsViewControllerControl : UIControl

@property (nonatomic, strong) UIView *customInputView;

@end

@implementation ProductsViewController

#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _shoppableSortTitles = @{@(ShoppableSortTypeSimilar): @"Similar",
                                 @(ShoppableSortTypePrice): @"Price",
                                 @(ShoppableSortTypeBrands): @"Brands"
                                 };
        
        self.title = @"Products";
        self.navigationItem.titleView = [self currentTitleView];
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
        toolbar.shoppables = [self shoppables];
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
    
    {
        UIImage *image = [UIImage imageWithData:self.screenshot.imageData];
        CGFloat buttonSize = 32.f;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0.f, 0.f, buttonSize, buttonSize);
        button.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(displayScreenshotAction) forControlEvents:UIControlEventTouchUpInside];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
        
        self.image = image;
        self.shoppablesToolbar.screenshotImage = image;
    }
    
    [self reloadCollectionViewForIndex:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.shoppablesToolbar selectFirstItem];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_didViewDidAppear) {
        [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
    }
    
    _didViewDidAppear = YES;
    
    [self presentTutorialHelperIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController.navigationBar endEditing:YES];
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
            self.shoppablesFrc = nil;
            [[DataModel sharedInstance] clearShoppableFrc];
        }
    }
}

- (void)displayScreenshotAction {
    ScreenshotDisplayNavigationController *navigationController = [[ScreenshotDisplayNavigationController alloc] init];
    navigationController.screenshotDisplayViewController.image = self.image;
    navigationController.screenshotDisplayViewController.shoppables = [self shoppables];
    [self presentViewController:navigationController animated:YES completion:nil];
}


#pragma mark - Shoppable / Products

- (BOOL)hasShoppables {
    return self.shoppablesFrc.fetchedObjects.count > 0;
}

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

- (NSArray<Product *> *)productsForShoppable:(Shoppable *)shoppable {
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    return [shoppable.products sortedArrayUsingDescriptors:@[descriptor]];
}


#pragma mark - Collection View

- (void)reloadCollectionViewForIndex:(NSInteger)index {
    self.products = [self productsForShoppable:[self shoppableAtIndex:index]];
    
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
    cell.title = product.brand.length ? product.brand : product.merchant;
    cell.price = product.price;
    cell.imageUrl = product.imageURL;
    cell.favoriteButton.selected = product.isFavorite;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Product *product = self.products[indexPath.item];
    
    WebViewController *webViewController = [[WebViewController alloc] init];
    [webViewController addNavigationItemLogo];
    webViewController.hidesBottomBarWhenPushed = YES;
    webViewController.url = [NSURL URLWithString:product.offer];
    
    [self.navigationController pushViewController:webViewController animated:YES];
    
    [AnalyticsManager track:@"Tapped on product" properties:@{@"merchant": product.merchant, @"brand": product.brand, @"page": @"Products"}];
    
    [FBSDKAppEvents logEvent:FBSDKAppEventNameViewedContent parameters:@{FBSDKAppEventParameterNameContentID: product.imageURL}];
}


#pragma mark - Product Cell

- (void)productCollectionViewCellDidTapFavorite:(ProductCollectionViewCell *)cell {
    BOOL isFavorited = [cell.favoriteButton isSelected];
    
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    Product *product = self.products[indexPath.item];
    [product setFavoritedToFavorited:isFavorited];
    
    NSString *favoriteString = isFavorited ? @"Product favorited" : @"Product unfavorited";
    [AnalyticsManager track:favoriteString properties:@{@"url": product.offer, @"imageUrl": product.imageURL}];
    
    NSString *value = isFavorited ? FBSDKAppEventParameterValueYes : FBSDKAppEventParameterValueNo;
    [FBSDKAppEvents logEvent:FBSDKAppEventNameAddedToWishlist parameters:@{FBSDKAppEventParameterNameSuccess: value}];
}


#pragma mark - Fetched Results Controller

- (void)frcOneAddedAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
}

- (void)frcOneDeletedAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
}

- (void)frcOneUpdatedAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

- (void)frcReloadData {
    [self.collectionView reloadData];
}


#pragma mark - Sorting

- (UIView *)currentTitleView {
    UILabel *label = [[UILabel alloc] init];
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = .7f;
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[[UINavigationBar appearance] titleTextAttributes]];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"Sort by: " attributes:attributes];
    
    [attributes setObject:[UIColor crazeGreen] forKey:NSForegroundColorAttributeName];
    
    NSAttributedString *sortString = [[NSAttributedString alloc] initWithString:self.shoppableSortTitles[@(self.currentSortType)] attributes:attributes];
    [attributedString appendAttributedString:sortString];
    
    CGFloat offset = 3.f;
    
    [attributes setObject:@(offset) forKey:NSBaselineOffsetAttributeName];
    
    NSAttributedString *arrowString = [[NSAttributedString alloc] initWithString:@"⌄" attributes:attributes];
    [attributedString appendAttributedString:arrowString];
    
    label.attributedText = attributedString;
    [label sizeToFit];
    
    CGRect rect = label.frame;
    rect.origin.y -= offset;
    label.frame = rect;
    
    ProductsViewControllerControl *container = [[ProductsViewControllerControl alloc] initWithFrame:label.bounds];
    [container addTarget:self action:@selector(presentSortPicker:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:label];
    return container;
}

- (void)presentSortPicker:(ProductsViewControllerControl *)control {
    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.delegate = self;
    picker.dataSource = self;
    picker.backgroundColor = [UIColor whiteColor];
    [picker selectRow:self.currentSortType inComponent:0 animated:NO];
    
    control.customInputView = picker;
    [control becomeFirstResponder];
}


#pragma mark - Picker View

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.shoppableSortTitles.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.shoppableSortTitles[@(row)];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.currentSortType = row;
    self.navigationItem.titleView = [self currentTitleView];
    [self.navigationController.navigationBar endEditing:YES];
}


#pragma mark - Toolbar

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

- (void)shoppablesToolbar:(ShoppablesToolbar *)toolbar didSelectShoppableAtIndex:(NSUInteger)index {
    [self reloadCollectionViewForIndex:index];
    
    [AnalyticsManager track:@"Tapped on shoppable"];
}


#pragma mark - Tutorial

- (void)presentTutorialHelperIfNeeded {
    BOOL hasPresented = [[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsKeys.tutorialPresentedProductHelper];
    NSString *tutorialScreenshotAssetId = [NSUserDefaults.standardUserDefaults stringForKey:UserDefaultsKeys. tutorialScreenshotAssetId];
    BOOL isTutorialScreenshot = [self.screenshot.assetId isEqualToString:tutorialScreenshotAssetId];
    
    if (!hasPresented && isTutorialScreenshot) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UserDefaultsKeys.tutorialPresentedProductHelper];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        self.transitioningController = [[TransitioningController alloc] init];
    
        NSArray<Shoppable *> *shoppables = [self shoppables];
        Product *product;
        
        for (Shoppable *shoppable in shoppables) {
            if ([shoppable.label isEqualToString:@"Jackets"]) {
                product = [[self productsForShoppable:shoppable] firstObject];
            }
        }
        
        if (!product) {
            product = [self.products firstObject];
        }
    
        TutorialProductsPageViewController *viewController = [[TutorialProductsPageViewController alloc] init];
        viewController.modalPresentationStyle = UIModalPresentationCustom;
        viewController.transitioningDelegate = self.transitioningController;
        viewController.product = product;
        [self presentViewController:viewController animated:YES completion:nil];
    }
}

@end

@implementation ProductsViewControllerControl

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (UIView *)inputView {
    return self.customInputView;
}

@end
