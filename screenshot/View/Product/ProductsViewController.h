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

@interface ProductsViewController : BaseViewController

@property (nonatomic, strong) Screenshot *screenshot;

- (Product *)productAtIndex:(NSInteger)index;
- (NSInteger)indexForProduct:(Product *)product;

- (void)reloadProductCellAtIndex:(NSInteger)index;

@end
