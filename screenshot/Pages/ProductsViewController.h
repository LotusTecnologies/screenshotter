//
//  ProductsViewController.h
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "BaseViewController.h"
#import "screenshot-Swift.h"

@class ProductsViewController;

@protocol ProductsViewControllerDelegate <NSObject>
@required

- (void)productsViewController:(ProductsViewController *)viewController didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface ProductsViewController : BaseViewController

@property (nonatomic, weak) id<ProductsViewControllerDelegate> delegate;
@property (nonatomic, strong) Screenshot *screenshot;

- (Product *)productAtIndexPath:(NSIndexPath *)indexPath;

@end
