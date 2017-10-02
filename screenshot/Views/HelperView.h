//
//  HelperView.h
//  screenshot
//
//  Created by Corey Werner on 8/16/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelperView : UIView

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
@property (nonatomic, strong, readonly) UIView *contentView;

//  Setting this will center an imageView in the contentView
@property (nonatomic, copy) UIImage *contentImage;

@end
