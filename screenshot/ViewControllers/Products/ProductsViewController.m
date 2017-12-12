//
//  ProductsViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ProductsViewController.h"
#import "ProductCollectionViewCell.h"
#import "ShoppablesToolbar.h"
#import "ScreenshotDisplayNavigationController.h"
#import "TutorialProductsPageViewController.h"

@import FBSDKCoreKit.FBSDKAppEvents;

typedef NS_ENUM(NSUInteger, ProductsSection) {
    ProductsSectionProduct
};

@interface ProductsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate, ProductCollectionViewCellDelegate, ShoppablesControllerProtocol, ShoppablesControllerDelegate, ShoppablesToolbarDelegate, ProductsOptionsDelegate>

@property (nonatomic, strong) Loader *loader;
@property (nonatomic, strong) HelperView *noItemsHelperView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) ShoppablesToolbar *shoppablesToolbar;
@property (nonatomic, strong) ProductsOptions *productsOptions;
@property (nonatomic, strong) ProductsRateView *rateView;
@property (nonatomic, strong) NSLayoutConstraint *rateViewTopConstraint;
@property (nonatomic) CGFloat rateViewOffsetY;
@property (nonatomic) CGFloat rateViewPreviousOffsetY;
@property (nonatomic, strong) UIAlertAction *productsRateNegativeFeedbackSubmitAction;
@property (nonatomic, strong) UITextField *productsRateNegativeFeedbackTextField;

@property (nonatomic, strong) NSArray<Product *> *products;

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
        _productsOptions = [[ProductsOptions alloc] init];
        self.productsOptions.delegate = self;
        
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
        button.layer.borderColor = [UIColor crazeGreen].CGColor;
        button.layer.borderWidth = 1.f;
        
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
        
        [button.widthAnchor constraintEqualToConstant:button.bounds.size.width].active = YES;
        [button.heightAnchor constraintEqualToConstant:button.bounds.size.height].active = YES;
        
        barButtonItem;
    });
    
    if (!self.shoppablesController || [self.shoppablesController shoppableCount] == -1) {
        // You shall not pass!
        [self showNoItemsHelperView];
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
        toolbar.barTintColor = [UIColor whiteColor];
        toolbar.hidden = [self shouldHideToolbar];
        [self.view addSubview:toolbar];
        [toolbar.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
        [toolbar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [toolbar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        [toolbar.heightAnchor constraintEqualToConstant:toolbar.bounds.size.height].active = YES;
        toolbar;
    });
    
    self.collectionView = ({
        UIEdgeInsets shadowInsets = [ScreenshotCollectionViewCell shadowInsets];
        CGFloat p = [Geometry padding];
        CGPoint minimumSpacing = CGPointMake(p - shadowInsets.left - shadowInsets.right, p - shadowInsets.top - shadowInsets.bottom);
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = minimumSpacing.x;
        layout.minimumLineSpacing = minimumSpacing.y;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
        collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.contentInset = UIEdgeInsetsMake(minimumSpacing.y + self.shoppablesToolbar.bounds.size.height, minimumSpacing.x, minimumSpacing.y, minimumSpacing.x);
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
    
    _rateView = ({
        ProductsRateView *view = [[ProductsRateView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.backgroundColor = [UIColor redColor];
        [view.voteUpButton addTarget:self action:@selector(productsRatePositiveAction) forControlEvents:UIControlEventTouchUpInside];
        [view.voteDownButton addTarget:self action:@selector(productsRateNegativeAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:view];
        _rateViewTopConstraint = [view.topAnchor constraintEqualToAnchor:self.view.bottomAnchor];
        self.rateViewTopConstraint.active = YES;
        [view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        
        CGFloat height = view.intrinsicContentSize.height;
        
        if (@available(iOS 11.0, *)) {
            height += [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
        }
        
        [view.heightAnchor constraintEqualToConstant:height].active = YES;
        view;
    });
    
    [self updateOptionsView];
    [self reloadCollectionViewForIndex:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.shoppablesToolbar selectFirstShoppable];
    
    if (![self hasShoppables] && !self.noItemsHelperView) {
        [self.loader startAnimation];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.shoppablesToolbar.didViewControllerAppear = YES;
    
    [self presentTutorialHelperIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self dismissOptions];
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
    
    switch ([self.productsOptions _sort]) {
        case 1: // == .similar
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES]];
            break;
            
        case 2: // == .priceAsc
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"floatPrice" ascending:YES]];
            break;
            
        case 3: // == .priceDes
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"floatPrice" ascending:NO]];
            break;
            
        case 4: // == .brands
            descriptors = @[[[NSSortDescriptor alloc] initWithKey:@"displayTitle" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)],
                            [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES]];
            break;
    }
    
    NSInteger mask = [[shoppable getLast] rawValue];
    NSSet<Product *> *products = [shoppable.products filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"(optionsMask & %d) == %d", mask, mask]];
    
    if ([self.productsOptions _sale] == 1) { // == .sale
        products = [products filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"floatPrice < floatOriginalPrice"]];
    }
    
    return [products sortedArrayUsingDescriptors:descriptors];
}

- (Product *)productAtIndex:(NSInteger)index {
    return self.products[index];
}

- (NSInteger)indexForProduct:(Product *)product {
    return [self.products indexOfObject:product];
}

- (void)shoppablesControllerIsEmpty:(ShoppablesController *)controller {
    if (!self.noItemsHelperView) {
        [self stopAndRemoveLoader];
        [self showNoItemsHelperView];
    }
}

- (void)shoppablesControllerDidReload:(ShoppablesController *)controller {
    [self reloadCollectionViewForIndex:[self.shoppablesToolbar selectedShoppableIndex]];
}


#pragma mark - Collection View

- (void)reloadCollectionViewForIndex:(NSInteger)index {
    if ([self hasShoppables]) {
        BOOL hadProducts = self.products.count > 0;
        Shoppable *shoppable = [self.shoppablesController shoppableAt:index];
        self.products = [self productsForShoppable:shoppable];
        
        (self.products.count == 0) ? [self.loader startAnimation] : [self stopAndRemoveLoader];
        
        if (hadProducts || self.products.count) {
            [self.collectionView reloadData];
            
            self.rateView.rating = [shoppable getRating];
        }
        
        if (self.products.count) {
            // TODO: maybe call setContentOffset:
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        }
        
    } else {
        self.products = @[];
    }
}

- (NSInteger)numberOfCollectionViewProductColumns {
    return 2;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == ProductsSectionProduct) {
        return self.products.count;
        
    } else {
        return 0;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeZero;
    UIEdgeInsets shadowInsets = [ScreenshotCollectionViewCell shadowInsets];
    CGFloat padding = [Geometry padding] - shadowInsets.left - shadowInsets.right;
    
    if (indexPath.section == ProductsSectionProduct) {
        NSInteger columns = [self numberOfCollectionViewProductColumns];
        
        size.width = floor((collectionView.bounds.size.width - (padding * (columns + 1))) / columns);
        size.height = size.width + [ProductCollectionViewCell labelsHeight];
    }
    
    return size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ProductsSectionProduct) {
        Product *product = [self productAtIndex:indexPath.item];
        
        ProductCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
        cell.delegate = self;
        cell.contentView.backgroundColor = collectionView.backgroundColor;
        cell.title = product.displayTitle;
        cell.price = product.price;
        cell.originalPrice = product.originalPrice;
        cell.imageUrl = product.imageURL;
        cell.isSale = [product isSale];
        cell.favoriteButton.selected = product.isFavorite;
        return cell;
        
    } else {
        return nil;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ProductsSectionProduct) {
        [self.delegate productsViewController:self didSelectItemAtIndexPath:indexPath];
        
        Product *product = [self productAtIndex:indexPath.item];
        
        // TODO: update to AnalyticsTrackers.standard.trackTappedOnProduct after swift conversion
        [AnalyticsTrackerObjCBridge trackTappedOnProductWithTracker:AnalyticsTrackers.standard
                                                            product:product
                                                             onPage:@"Products"];
        
        NSString *email = [[NSUserDefaults standardUserDefaults] stringForKey:[UserDefaultsKeys email]];
        
        if (email.length) {
            NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:[UserDefaultsKeys name]] ?: @"";
            
            [AnalyticsTrackers.standard track:@"Product for email" properties:@{@"screenshot": self.screenshot.uploadedImageURL,
                                                                                @"merchant": product.merchant,
                                                                                @"brand": product.brand,
                                                                                @"title": product.displayTitle,
                                                                                @"url": product.offer,
                                                                                @"imageUrl": product.imageURL,
                                                                                @"price": product.price,
                                                                                @"email": email,
                                                                                @"name": name
                                                                                }];
        }
        
        [AnalyticsTrackers.branch track:@"Tapped on product" properties:nil];
        
        [FBSDKAppEvents logEvent:FBSDKAppEventNameViewedContent parameters:@{FBSDKAppEventParameterNameContentID: product.imageURL}];
    }
}


#pragma mark - Product Cell

- (void)productCollectionViewCellDidTapFavorite:(ProductCollectionViewCell *)cell {
    BOOL isFavorited = [cell.favoriteButton isSelected];
    
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    Product *product = [self productAtIndex:indexPath.item];
    [product setFavoritedToFavorited:isFavorited];
    
    NSString *favoriteString = isFavorited ? @"Product favorited" : @"Product unfavorited";
    
    [AnalyticsTrackers.standard track:favoriteString properties:@{@"merchant": product.merchant,
                                                                  @"brand": product.brand,
                                                                  @"url": product.offer,
                                                                  @"imageUrl": product.imageURL,
                                                                  @"page": @"Products"
                                                                  }];
    
    NSString *value = isFavorited ? FBSDKAppEventParameterValueYes : FBSDKAppEventParameterValueNo;
    [FBSDKAppEvents logEvent:FBSDKAppEventNameAddedToWishlist parameters:@{FBSDKAppEventParameterNameSuccess: value}];
}

- (void)reloadProductCellAtIndex:(NSInteger)index {
    if ([self.collectionView numberOfItemsInSection:ProductsSectionProduct] > index) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:ProductsSectionProduct];
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
}


#pragma mark - Scroll View

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self dismissOptions];
    [self resetRateViewOffsetY:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([scrollView isDragging]) {
        CGFloat expectedContentOffsetY = [self scrollViewExpectedContentOffsetY:scrollView];
        CGFloat expectedContentSizeHeight = [self scrollViewExpectedContentSizeHeight:scrollView];
        
        // Dont change the constraint when bouncing
        if (expectedContentOffsetY > 0 && expectedContentSizeHeight < scrollView.contentSize.height) {
            self.rateViewTopConstraint.constant = MIN(0.f, MAX(-self.rateView.bounds.size.height, self.rateViewOffsetY - scrollView.contentOffset.y));
        }
        
        [self resetRateViewOffsetY:scrollView];
        self.rateViewPreviousOffsetY = scrollView.contentOffset.y;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self animateRateViewIfNeeded];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self animateRateViewIfNeeded];
}

- (UIEdgeInsets)scrollViewAjustedContentInset:(UIScrollView *)scrollView {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    
    if (@available(iOS 11.0, *)) {
        insets.top = scrollView.adjustedContentInset.top;
        insets.bottom = scrollView.adjustedContentInset.bottom;
        
    } else {
        insets.top = CGRectGetMaxY(self.navigationController.navigationBar.frame) + scrollView.contentInset.top;
        insets.bottom = scrollView.contentInset.bottom;
    }
    
    return insets;
}

- (CGFloat)scrollViewExpectedContentOffsetY:(UIScrollView *)scrollView {
    UIEdgeInsets ajustedContentInset = [self scrollViewAjustedContentInset:scrollView];
    return scrollView.contentOffset.y + ajustedContentInset.top;
}

- (CGFloat)scrollViewExpectedContentSizeHeight:(UIScrollView *)scrollView {
    UIEdgeInsets ajustedContentInset = [self scrollViewAjustedContentInset:scrollView];
    return scrollView.contentOffset.y + scrollView.bounds.size.height - ajustedContentInset.bottom;
}

- (void)resetRateViewOffsetY:(UIScrollView *)scrollView {
    self.rateViewOffsetY = scrollView.contentOffset.y + self.rateViewTopConstraint.constant;
}

- (void)animateRateViewIfNeeded {
    CGFloat minHeight = -self.rateView.bounds.size.height;
    CGFloat maxHeight = 0.f;
    CGFloat offsetY = self.rateViewTopConstraint.constant;
    
    if (offsetY > minHeight && offsetY < maxHeight) {
        [UIView animateWithDuration:[Constants defaultAnimationDuration] animations:^{
            self.rateViewTopConstraint.constant = (offsetY * 2.f > minHeight) ? maxHeight : minHeight;
            [self.view layoutIfNeeded];
        }];
    }
}


#pragma mark - Products Options

- (UIView *)currentOptionsView {
    UILabel *label = [[UILabel alloc] init];
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = .7f;
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[[UINavigationBar appearance] titleTextAttributes]];
    [attributes setObject:[UIColor crazeGreen] forKey:NSForegroundColorAttributeName];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"Sort & Filter" attributes:attributes];
    
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
    [container addTarget:self action:@selector(presentOptions:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:label];
    return container;
}

- (void)updateOptionsView {
    if ([self hasShoppables]) {
        if (!self.navigationItem.titleView) {
            self.navigationItem.titleView = [self currentOptionsView];
        }
    } else {
        self.navigationItem.titleView = nil;
    }
}

- (void)presentOptions:(ProductsViewControllerControl *)control {
    if ([control isFirstResponder]) {
        [control resignFirstResponder];
        
    } else {
        Shoppable *shoppable = [self.shoppablesController shoppableAt:[self.shoppablesToolbar selectedShoppableIndex]];
        [self.productsOptions syncOptionsWithMask:[shoppable getLast]];
        
        control.customInputView = self.productsOptions.view;
        [control becomeFirstResponder];
    }
}

- (void)dismissOptions {
    [self.navigationItem.titleView endEditing:YES];
}

- (void)productsOptionsDidComplete:(ProductsOptions *)productsOptions withChange:(BOOL)changed {
    if (changed) {
        Shoppable *shoppable = [self.shoppablesController shoppableAt:[self.shoppablesToolbar selectedShoppableIndex]];
        [shoppable setWithProductsOptions:productsOptions callback:^{
            [self reloadCollectionViewForIndex:[self.shoppablesToolbar selectedShoppableIndex]];
        }];
    }
    
    [self dismissOptions];
}


#pragma mark - Rate View

- (void)productsRatePositiveAction {
    Shoppable *shoppable = [self.shoppablesController shoppableAt:[self.shoppablesToolbar selectedShoppableIndex]];
    [shoppable setRatingWithPositive:YES];
    
    [AnalyticsTrackers.standard track:@"Shoppable rating positive" properties:nil];
}

- (void)productsRateNegativeAction {
    Shoppable *shoppable = [self.shoppablesController shoppableAt:[self.shoppablesToolbar selectedShoppableIndex]];
    [shoppable setRatingWithPositive:NO];
    
    [self presentProductsRateNegativeAlert];
    
    [AnalyticsTrackers.standard track:@"Shoppable rating negative" properties:nil];
}

- (void)presentProductsRateNegativeAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Sorry To Hear That!" message:@"We hear you loud and clear and we’re going to look into this. How else can we help?" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Send Feedback" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self presentProductsRateNegativeFeedbackAlert];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Get Fashion Help" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *prefilledMessage = [NSString stringWithFormat:@"I need help finding this outfit... %@", self.screenshot.uploadedImageURL ?: @"null"];
        [IntercomHelper.sharedInstance presentMessageComposerWithInitialMessage:prefilledMessage];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)presentProductsRateNegativeFeedbackAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"What’s Wrong Here?" message:@"What were you expecting to see and what did you see instead?" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.delegate = self;
        textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        textField.enablesReturnKeyAutomatically = YES;
        self.productsRateNegativeFeedbackTextField = textField;
    }];
    
    self.productsRateNegativeFeedbackSubmitAction = [UIAlertAction actionWithTitle:@"Submit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Even though we're using `enablesReturnKeyAutomatically` custom keyboards might not support this.
        NSString *trimmedText = [self.productsRateNegativeFeedbackTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (trimmedText.length > 0) {
            [AnalyticsTrackers.segment track:@"Shoppable Feedback Negative" properties:@{@"text": trimmedText}];
        }
    }];
    self.productsRateNegativeFeedbackSubmitAction.enabled = NO;
    [alertController addAction:self.productsRateNegativeFeedbackSubmitAction];
    alertController.preferredAction = self.productsRateNegativeFeedbackSubmitAction;
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - Text Field

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSString *trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    self.productsRateNegativeFeedbackSubmitAction.enabled = (trimmedText.length > 0);
    
    return YES;
}


#pragma mark - Toolbar

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

- (void)shoppablesToolbarDidChange:(ShoppablesToolbar *)toolbar {
    if (self.products.count == 0 && [self isViewLoaded]) {
        [self stopAndRemoveLoader];
        
        toolbar.hidden = [self shouldHideToolbar];
        
        [self updateOptionsView];
        [self reloadCollectionViewForIndex:0];
    }
}

- (void)shoppablesToolbar:(ShoppablesToolbar *)toolbar didSelectShoppableAtIndex:(NSUInteger)index {
    [self reloadCollectionViewForIndex:index];
    
    [AnalyticsTrackers.standard track:@"Tapped on shoppable" properties:nil];
}

- (BOOL)shouldHideToolbar {
    return ![self hasShoppables];
}


#pragma mark - Tutorial

- (void)presentTutorialHelperIfNeeded {
    BOOL hasPresented = [[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsKeys.onboardingPresentedProductHelper];
    
    if (!hasPresented) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UserDefaultsKeys.onboardingPresentedProductHelper];
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

- (void)showNoItemsHelperView {
    CGFloat verPadding = [Geometry extendedPadding];
    CGFloat horPadding = [Geometry padding];
    
    HelperView *helperView = [[HelperView alloc] init];
    helperView.translatesAutoresizingMaskIntoConstraints = NO;
    helperView.layoutMargins = UIEdgeInsetsMake(verPadding, horPadding, verPadding, horPadding);
    helperView.backgroundColor = self.view.backgroundColor;
    helperView.titleLabel.text = @"No Items Found";
    helperView.subtitleLabel.text = @"No visually similar products were detected";
    helperView.contentImage = [UIImage imageNamed:@"ProductsEmptyListGraphic"];
    [self.view addSubview:helperView];
    [helperView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
    [helperView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [helperView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [helperView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    self.noItemsHelperView = helperView;
    
    MainButton *retryButton = [MainButton buttonWithType:UIButtonTypeCustom];
    retryButton.translatesAutoresizingMaskIntoConstraints = NO;
    retryButton.backgroundColor = [UIColor crazeGreen];
    [retryButton setTitle:@"Try Again" forState:UIControlStateNormal];
    [retryButton addTarget:self action:@selector(noItemsRetryAction) forControlEvents:UIControlEventTouchUpInside];
    [helperView.controlView addSubview:retryButton];
    [retryButton.topAnchor constraintEqualToAnchor:helperView.controlView.topAnchor].active = YES;
    [retryButton.bottomAnchor constraintEqualToAnchor:helperView.controlView.bottomAnchor].active = YES;
    [retryButton.centerXAnchor constraintEqualToAnchor:helperView.contentView.centerXAnchor].active = YES;
    
    [AnalyticsTrackers.standard track:@"Screenshot Opened Without Shoppables" properties:nil];
}

- (void)hideNoItemsHelperView {
    [self.noItemsHelperView removeFromSuperview];
    self.noItemsHelperView = nil;
}

- (void)noItemsRetryAction {
    [self.shoppablesController refetchShoppables];
    [self hideNoItemsHelperView];
    [self.loader startAnimation];
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
