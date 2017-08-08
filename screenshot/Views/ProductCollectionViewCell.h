//
//  ProductCollectionViewCell.h
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProductCollectionViewCell : UICollectionViewCell

@property (nonatomic, copy) UIImage *image;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *price;

@property (nonatomic, strong, readonly) UIButton *favoriteButton;

+ (CGFloat)labelsHeight;

@end
