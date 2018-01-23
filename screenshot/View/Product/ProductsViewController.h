//
//  ProductsViewController.h
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "BaseViewController.h"

@class ProductsViewController;
@class Screenshot, Product;

@protocol ProductsViewControllerDelegate <NSObject>
@required

- (void)productsViewController:(ProductsViewController *)viewController didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface ProductsViewController : BaseViewController

@property (nonatomic, weak) id<ProductsViewControllerDelegate> delegate;

@property (nonatomic, strong) Screenshot *screenshot;

- (Product *)productAtIndex:(NSInteger)index;
- (NSInteger)indexForProduct:(Product *)product;

- (void)reloadProductCellAtIndex:(NSInteger)index;

@end
