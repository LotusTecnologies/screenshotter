//
//  ProductsViewController.h
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "BaseViewController.h"

typedef NS_ENUM(NSUInteger, ProductsSection) {
    ProductsSectionTooltip,
    ProductsSectionProduct
};

typedef NS_ENUM(NSUInteger, ProductsViewControllerState) {
    ProductsViewControllerStateLoading,
    ProductsViewControllerStateProducts,
    ProductsViewControllerStateRetry,
    ProductsViewControllerStateEmpty
};

@class ProductsViewController;
@class Screenshot, Product, HelperView, Loader, ShoppablesToolbar, ProductsOptions, ScrollRevealController, ProductsRateView;

@interface ProductsViewController : BaseViewController

@property (nonatomic, strong) Screenshot *screenshot;

- (Product *)productAtIndex:(NSInteger)index;
- (NSInteger)indexForProduct:(Product *)product;

- (void)reloadProductCellAtIndex:(NSInteger)index;



//private

@property (nonatomic, strong) Loader *loader;
@property (nonatomic, strong) HelperView *noItemsHelperView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) ShoppablesToolbar *shoppablesToolbar;
@property (nonatomic, strong) ProductsOptions *productsOptions;
@property (nonatomic, strong) ScrollRevealController *scrollRevealController;
@property (nonatomic, strong) ProductsRateView *rateView;
@property (nonatomic, strong) UIAlertAction *productsRateNegativeFeedbackSubmitAction;
@property (nonatomic, strong) UITextField *productsRateNegativeFeedbackTextField;

@property (nonatomic, strong) NSArray<Product *> *products;
@property (nonatomic) NSUInteger productsUnfilteredCount;

@property (nonatomic, copy) UIImage *image;

@property (nonatomic) ProductsViewControllerState state;

@end
