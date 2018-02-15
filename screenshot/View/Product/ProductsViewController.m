//
//  ProductsViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ProductsViewController.h"
#import "screenshot-Swift.h"
#import <PromiseKit/PromiseKit.h>

@import FBSDKCoreKit.FBSDKAppEvents;


@interface ProductsViewController () 

@end

@implementation ProductsViewController
@synthesize shoppablesController = _shoppablesController;


#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentSizeCategoryDidChange:) name:UIContentSizeCategoryDidChangeNotification object:nil];
        
        _productsOptions = [[ProductsOptions alloc] init];
        self.productsOptions.delegate = self;
    }
    return self;
}

- (NSString *)title {
    return @"Products";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupShoppableToolbar];
    
    [self setupCollectionView];
    
    
    self.rateView = ({
        ProductsRateView *view = [[ProductsRateView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [view.voteUpButton addTarget:self action:@selector(productsRatePositiveAction) forControlEvents:UIControlEventTouchUpInside];
        [view.voteDownButton addTarget:self action:@selector(productsRateNegativeAction) forControlEvents:UIControlEventTouchUpInside];
        [view.talkToYourStylistButton addTarget:self action:@selector(talkToYourStylistAction) forControlEvents:UIControlEventTouchUpInside];

        view;
    });
    [self setupViews];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.shoppablesToolbar selectFirstShoppable];
    
    if (![self hasShoppables] && !self.noItemsHelperView) {
        self.state = ProductsViewControllerStateLoading;
    }
    
    [ProductWebViewController shared].lifeCycleDelegate = self;
    [ProductWebViewController shared].delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.shoppablesToolbar.didViewControllerAppear = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self dismissOptions];
}

- (void)viewController:(UIViewController *)viewController willDisappear:(BOOL)animated {
    if (viewController == [ProductWebViewController shared] && [self.navigationController.topViewController isKindOfClass:[ProductsViewController class]]) {
        ProductsViewController *productsViewController = (ProductsViewController *)self.navigationController.topViewController;
        NSInteger index = [productsViewController indexForProduct:[ProductWebViewController shared].product];
        [productsViewController reloadProductCellAtIndex:index];
    }
}

- (void)viewController:(UIViewController *)viewController didDisappear:(BOOL)animated {
    if (viewController == [ProductWebViewController shared] && ![self.navigationController.viewControllers containsObject:viewController]) {
        [ProductWebViewController shared].product = nil;
    }
}

- (void)contentSizeCategoryDidChange:(NSNotification *)notification {
    if (self.view.window && [self.collectionView numberOfItemsInSection:ProductsSectionTooltip] > 0) {
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:ProductsSectionTooltip]]];
    }
}

- (void)dealloc {
    self.shoppablesToolbar.delegate = nil;
    self.shoppablesToolbar.shoppableToolbarDelegate = nil;
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    self.shoppablesController.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - State

- (void)setState:(ProductsViewControllerState)state {
    _state = state;
    [self syncViewsAfterStateChange];
    
}


#pragma mark - Screenshot

- (void)setScreenshot:(Screenshot *)screenshot {
    if (_screenshot != screenshot) {
        _screenshot = screenshot;
        
        self.shoppablesController = screenshot ? [[ShoppablesController alloc] initWithScreenshot:screenshot] : nil;
        self.shoppablesController.delegate = self;
        
        if ([self isViewLoaded]) {
            [self syncScreenshotRelatedObjects];
            [self reloadProductsForShoppableAtIndex:0];
        }
    }
}

- (void)displayScreenshotAction {
    ScreenshotDisplayNavigationController *navigationController = [[ScreenshotDisplayNavigationController alloc] init];
    navigationController.screenshotDisplayViewController.image = self.image;
    navigationController.screenshotDisplayViewController.shoppables = [self.shoppablesController shoppables];
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - Product Cell

- (void)productCollectionViewCellDidTapFavoriteWithCell:(ProductCollectionViewCell *)cell {
    BOOL isFavorited = [cell.favoriteButton isSelected];
    
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    Product *product = [self productAtIndex:indexPath.item];
    [product setFavoritedToFavorited:isFavorited];
    
    [AnalyticsTrackerObjCBridge trackFavoritedProductWithTracker:AnalyticsTrackers.standard favorited:isFavorited product:product onPage:@"Products"];
}

- (void)reloadProductCellAtIndex:(NSInteger)index {
    if ([self.collectionView numberOfItemsInSection:ProductsSectionProduct] > index) {
        [self.collectionView reloadItemsAtIndexPaths:@[[self shoppablesFrcToCollectionViewIndexPath:index]]];
    }
}


#pragma mark - Scroll View

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self dismissOptions];
    [self.scrollRevealController scrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.scrollRevealController scrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.scrollRevealController scrollViewDidEndDragging:scrollView will:decelerate];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.scrollRevealController scrollViewDidEndDecelerating:scrollView];
}


#pragma mark - Fetched Results Controller

- (NSIndexPath *)collectionViewToShoppablesFrcIndexPath:(NSInteger)index {
    return [NSIndexPath indexPathForItem:index inSection:0];
}

- (NSIndexPath *)shoppablesFrcToCollectionViewIndexPath:(NSInteger)index {
    return [NSIndexPath indexPathForItem:index inSection:ProductsSectionProduct];
}


#pragma mark - Products Options


- (void)productsOptionsDidComplete:(ProductsOptions *)productsOptions withChange:(BOOL)changed {
    if (changed) {
        Shoppable *shoppable = [self.shoppablesController shoppableAt:[self.shoppablesToolbar selectedShoppableIndex]];
        [shoppable setWithProductsOptions:productsOptions callback:^{
            [self reloadProductsForShoppableAtIndex:[self.shoppablesToolbar selectedShoppableIndex]];
        }];
    }
    
    [self dismissOptions];
}


#pragma mark - Rate View

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

-(void) shoppablesToolbarDidChangeWithToolbar:(ShoppablesToolbar *)toolbar{
    if (self.products.count == 0 && [self isViewLoaded]) {
        [self reloadProductsForShoppableAtIndex:0];
    }
}

    
-(void) shoppablesToolbarDidSelectShoppableWithToolbar:(ShoppablesToolbar *)toolbar index:(NSInteger)index {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[UserDefaultsKeys productCompletedTooltip]];
    
    [self reloadProductsForShoppableAtIndex:index];
    
    [AnalyticsTrackers.standard track:@"Tapped on shoppable" properties:nil];
}

- (BOOL)shouldHideToolbar {
    return ![self hasShoppables];
}




#pragma mark - Web View Controller

- (void)webViewController:(WebViewController *)viewController declinedInvalidURL:(NSURL *)url {
    [self.navigationController popViewControllerAnimated:YES];
    [self presentViewController:viewController.declinedInvalidURLAlertController animated:YES completion:nil];
}

@end

