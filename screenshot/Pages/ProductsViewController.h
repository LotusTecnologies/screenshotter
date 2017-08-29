//
//  ProductsViewController.h
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "BaseViewController.h"
#import "screenshot-Swift.h"

@interface ProductsViewController : BaseViewController

@property (nonatomic, strong) Screenshot *screenshot;

- (BOOL)hasShoppables;

@end
