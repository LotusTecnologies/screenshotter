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
#import "TutorialProductsPageViewController.h"
#import "TransitioningController.h"
#import "Loader.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

typedef NS_ENUM(NSUInteger, ShoppableSortType) {
    ShoppableSortTypeSimilar,
    ShoppableSortTypePrice,
    ShoppableSortTypeBrands
};

@interface ProductsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, ProductCollectionViewCellDelegate, ShoppablesControllerProtocol, ShoppablesControllerDelegate, ShoppablesToolbarDelegate> {
    BOOL _didViewDidAppear;
}

@property (nonatomic, strong) Loader *loader;
@property (nonatomic, strong) HelperView *noItemsHelperView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) ShoppablesToolbar *shoppablesToolbar;

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
@synthesize shoppablesController = _shoppablesController;


#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _shoppableSortTitles = @{@(ShoppableSortTypeSimilar): @"Similar",
                                 @(ShoppableSortTypePrice): @"Price",
                                 @(ShoppableSortTypeBrands): @"Brands"
                                 };
        
        self.title = @"Products";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.image = [UIImage imageWithData:self.screenshot.imageData];
    
    self.navigationItem.rightBarButtonItem = ({
        CGFloat buttonSize = 32.f;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0.f, 0.f, buttonSize, buttonSize);
        button.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [button setImage:self.image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(displayScreenshotAction) forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
        
        [button.widthAnchor constraintEqualToConstant:button.bounds.size.width].active = YES;
        [button.heightAnchor constraintEqualToConstant:button.bounds.size.height].active = YES;
        
        barButtonItem;
    });
    
    if (!self.shoppablesController || [self.shoppablesController shoppableCount] == -1) {
        // You shall not pass!
        [self displayNoItemsHelperView];
        return;
    }
    
    self.shoppablesToolbar = ({
        CGFloat margin = 8.5f; // Anything other then 8 will display horizontal margin
        CGFloat shoppableHeight = 60.f;
        
        ShoppablesToolbar *toolbar = [[ShoppablesToolbar alloc] initWithFrame:CGRectMake(0.f, 0.f, 0.f, margin * 2 + shoppableHeight)];
        toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        toolbar.screenshotImage = self.image;
        toolbar.shoppablesController = self.shoppablesController;
        toolbar.delegate = self;
        toolbar.hidden = [self shouldHideToolbar];
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
        collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        
        [collectionView registerClass:[ProductCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        
        [self.view insertSubview:collectionView atIndex:0];
        [collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        [collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
        [collectionView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
        [collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        collectionView;
    });
    
    [self reloadCollectionViewForIndex:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.shoppablesToolbar selectFirstShoppable];
    
    if (![self hasShoppables] && !self.noItemsHelperView) {
        [self.loader startAnimation:LoaderAnimationSpin];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.shoppablesToolbar.didViewControllerAppear = YES;
    
    if (_didViewDidAppear) {
        [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
    }
    
    _didViewDidAppear = YES;
    
    [self presentTutorialHelperIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self dismissSortPicker];
}

- (void)dealloc {
    self.shoppablesToolbar.delegate = nil;
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    self.shoppablesController.delegate = nil;
}


#pragma mark - Screenshot

- (void)setScreenshot:(Screenshot *)screenshot {
    if (_screenshot != screenshot) {
        _screenshot = screenshot;
        
        self.shoppablesController = screenshot ? [[ShoppablesController alloc] initWithScreenshot:screenshot] : nil;
        self.shoppablesController.delegate = self;
    }
}

- (void)displayScreenshotAction {
    ScreenshotDisplayNavigationController *navigationController = [[ScreenshotDisplayNavigationController alloc] init];
    navigationController.screenshotDisplayViewController.image = self.image;
    navigationController.screenshotDisplayViewController.shoppables = [self.shoppablesController shoppables];
    [self presentViewController:navigationController animated:YES completion:nil];
}


#pragma mark - Shoppable / Products

- (BOOL)hasShoppables {
    return [self.shoppablesController shoppableCount];
}

- (NSArray<Product *> *)productsForShoppable:(Shoppable *)shoppable {
    NSArray<NSSortDescriptor *> *descriptors;
    
    switch (self.currentSortType) {
        case ShoppableSortTypeSimilar:
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES]];
            break;
            
        case ShoppableSortTypePrice:
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"floatPrice" ascending:YES]];
            break;
            
        case ShoppableSortTypeBrands:
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"displayTitle" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)],
                            [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES]];
            break;
    }
    
    return [shoppable.products sortedArrayUsingDescriptors:descriptors];
}

- (void)shoppablesControllerIsEmpty:(ShoppablesController *)controller {
    if (!self.noItemsHelperView) {
        [self stopAndRemoveLoader];
        [self displayNoItemsHelperView];
    }
}


#pragma mark - Collection View

- (void)reloadCollectionViewForIndex:(NSInteger)index {
    [self updateSortView];
    
    if ([self hasShoppables]) {
        self.products = [self productsForShoppable:[self.shoppablesController shoppableAt:index]];
        
        [self.collectionView reloadData];
        
        if (self.products.count) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        }
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
    cell.title = product.displayTitle;
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
    webViewController.loaderLabelText = @"Loading your store...";
    webViewController.url = [NSURL URLWithString:product.offer];
    
    [self.navigationController pushViewController:webViewController animated:YES];
    
    [AnalyticsTrackers.branch track:@"Tapped on product"];
    [AnalyticsTrackers.standard track:@"Tapped on product" properties:@{@"merchant": product.merchant, @"brand": product.brand, @"page": @"Products"}];
    
    [FBSDKAppEvents logEvent:FBSDKAppEventNameViewedContent parameters:@{FBSDKAppEventParameterNameContentID: product.imageURL}];
}


#pragma mark - Product Cell

- (void)productCollectionViewCellDidTapFavorite:(ProductCollectionViewCell *)cell {
    BOOL isFavorited = [cell.favoriteButton isSelected];
    
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    Product *product = self.products[indexPath.item];
    [product setFavoritedToFavorited:isFavorited];
    
    NSString *favoriteString = isFavorited ? @"Product favorited" : @"Product unfavorited";
    [AnalyticsTrackers.standard track:favoriteString properties:@{@"url": product.offer, @"imageUrl": product.imageURL}];
    
    NSString *value = isFavorited ? FBSDKAppEventParameterValueYes : FBSDKAppEventParameterValueNo;
    [FBSDKAppEvents logEvent:FBSDKAppEventNameAddedToWishlist parameters:@{FBSDKAppEventParameterNameSuccess: value}];
}


#pragma mark - Scroll View

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self dismissSortPicker];
}


#pragma mark - Sorting

- (UIView *)currentSortView {
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

- (void)updateSortView {
    self.navigationItem.titleView = [self hasShoppables] ? [self currentSortView] : nil;
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

- (void)dismissSortPicker {
    [self.navigationItem.titleView endEditing:YES];
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
    [self reloadCollectionViewForIndex:[self.shoppablesToolbar selectedShoppableIndex]];
    [self.navigationController.navigationBar endEditing:YES];
}


#pragma mark - Toolbar

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

- (void)shoppablesToolbarDidChange:(ShoppablesToolbar *)toolbar {
    if (!self.products && [self isViewLoaded]) {
        [self stopAndRemoveLoader];
        
        toolbar.hidden = [self shouldHideToolbar];
        
        [self reloadCollectionViewForIndex:0];
    }
}

- (void)shoppablesToolbar:(ShoppablesToolbar *)toolbar didSelectShoppableAtIndex:(NSUInteger)index {
    [self reloadCollectionViewForIndex:index];
    
    [AnalyticsTrackers.standard track:@"Tapped on shoppable"];
}

- (BOOL)shouldHideToolbar {
    return ![self hasShoppables];
}


#pragma mark - Tutorial

- (void)presentTutorialHelperIfNeeded {
    BOOL hasPresented = [[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsKeys.tutorialPresentedProductHelper];
    
    if (!hasPresented) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UserDefaultsKeys.tutorialPresentedProductHelper];
        [[NSUserDefaults standardUserDefaults] synchronize];
    
        self.transitioningController = [[TransitioningController alloc] init];
    
        TutorialProductsPageViewController *viewController = [[TutorialProductsPageViewController alloc] init];
        viewController.modalPresentationStyle = UIModalPresentationCustom;
        viewController.transitioningDelegate = self.transitioningController;
        [self presentViewController:viewController animated:YES completion:nil];
    }
}


#pragma mark - Loader

- (Loader *)loader {
    if (!_loader) {
        _loader = [[Loader alloc] init];
        _loader.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:_loader];
        [_loader.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
        [_loader.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
    }
    return _loader;
}

- (void)stopAndRemoveLoader {
    if (_loader) {
        [self.loader stopAnimation];
        [self.loader removeFromSuperview];
        _loader = nil;
    }
}


#pragma mark - Helper View

- (void)displayNoItemsHelperView {
    CGFloat p2 = [Geometry extendedPadding];
    
    HelperView *helperView = [[HelperView alloc] init];
    helperView.translatesAutoresizingMaskIntoConstraints = NO;
    helperView.userInteractionEnabled = NO;
    helperView.backgroundColor = self.view.backgroundColor;
    helperView.titleLabel.text = @"No Items Found";
    helperView.subtitleLabel.text = @"No visually similar products were detected";
    helperView.contentImage = [UIImage imageNamed:@"ProductsEmptyListGraphic"];
    [self.view addSubview:helperView];
    [helperView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:p2].active = YES;
    [helperView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [helperView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor constant:-p2].active = YES;
    [helperView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    self.noItemsHelperView = helperView;
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
