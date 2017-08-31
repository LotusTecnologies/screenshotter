//
//  TutorialProductsPageViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/31/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialProductsPageViewController.h"
#import "UIColor+Appearance.h"
#import "Button.h"
#import "Geometry.h"

@import SDWebImage.UIImageView_WebCache;

@interface ProductsPageHelperView : UIView

@property (nonatomic, strong) UIImageView *productImageView;
@property (nonatomic, strong) UILabel *productBrandLabel;
@property (nonatomic, strong) UILabel *productPriceLabel;
@property (nonatomic, strong) Button *button;

@end

@interface TutorialProductsPageViewController ()

@property (nonatomic, strong) ProductsPageHelperView *view;

@end

@implementation ProductsPageHelperView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        CGFloat p = [Geometry padding];
        
        UIView *topContainerView = [[UIView alloc] init];
        topContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        topContainerView.backgroundColor = [UIColor colorWithWhite:244.f/255.f alpha:1.f];
        [self addSubview:topContainerView];
        [topContainerView.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
        [topContainerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
        [topContainerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
        [topContainerView.heightAnchor constraintEqualToConstant:[self topContentHeight]].active = YES;
        
        UIView *topContentView = [[UIView alloc] init];
        topContentView.translatesAutoresizingMaskIntoConstraints = NO;
        [topContainerView addSubview:topContentView];
        [topContentView.topAnchor constraintGreaterThanOrEqualToAnchor:topContainerView.topAnchor constant:p].active = YES;
        [topContentView.leadingAnchor constraintEqualToAnchor:topContainerView.leadingAnchor constant:p].active = YES;
        [topContentView.bottomAnchor constraintLessThanOrEqualToAnchor:topContainerView.bottomAnchor constant:-p].active = YES;
        [topContentView.trailingAnchor constraintEqualToAnchor:topContainerView.trailingAnchor constant:-p].active = YES;
        [topContentView.centerYAnchor constraintEqualToAnchor:topContainerView.centerYAnchor].active = YES;
        
        UIView *shoppableContentView = [[UIView alloc] init];
        shoppableContentView.translatesAutoresizingMaskIntoConstraints = NO;
        [topContentView addSubview:shoppableContentView];
        [shoppableContentView.topAnchor constraintEqualToAnchor:topContentView.topAnchor].active = YES;
        [shoppableContentView.leadingAnchor constraintGreaterThanOrEqualToAnchor:topContentView.leadingAnchor].active = YES;
        [shoppableContentView.trailingAnchor constraintLessThanOrEqualToAnchor:topContentView.trailingAnchor].active = YES;
        [shoppableContentView.centerXAnchor constraintEqualToAnchor:topContentView.centerXAnchor].active = YES;
        
        NSUInteger total = 3;
        UIImageView *previousImageView;
        
        for (int i = 0; i < total; i++) {
            NSString *imageName = [NSString stringWithFormat:@"TutorialProductsPageShoppable%d", i + 1];
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            [shoppableContentView addSubview:imageView];
            [imageView.topAnchor constraintEqualToAnchor:shoppableContentView.topAnchor].active = YES;
            [imageView.bottomAnchor constraintEqualToAnchor:shoppableContentView.bottomAnchor].active = YES;
            
            if (i == 0) {
                imageView.layer.borderColor = [UIColor crazeRedColor].CGColor;
                imageView.layer.borderWidth = 2.f;
                [imageView.leadingAnchor constraintEqualToAnchor:shoppableContentView.leadingAnchor].active = YES;
                
            } else {
                [imageView.leadingAnchor constraintEqualToAnchor:previousImageView.trailingAnchor constant:p].active = YES;
            }
            
            if (i == total -1) {
                [imageView.trailingAnchor constraintEqualToAnchor:shoppableContentView.trailingAnchor].active = YES;
            }
            
            previousImageView = imageView;
        }
        
        UILabel *shoppableLabel = [[UILabel alloc] init];
        shoppableLabel.translatesAutoresizingMaskIntoConstraints = NO;
        shoppableLabel.text = @"Switch between different items";
        shoppableLabel.textAlignment = NSTextAlignmentCenter;
        shoppableLabel.minimumScaleFactor = .7f;
        shoppableLabel.adjustsFontSizeToFitWidth = YES;
        shoppableLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        [topContentView addSubview:shoppableLabel];
        [shoppableLabel.topAnchor constraintEqualToAnchor:shoppableContentView.bottomAnchor constant:p].active = YES;
        [shoppableLabel.leadingAnchor constraintEqualToAnchor:topContentView.leadingAnchor].active = YES;
        [shoppableLabel.bottomAnchor constraintEqualToAnchor:topContentView.bottomAnchor].active = YES;
        [shoppableLabel.trailingAnchor constraintEqualToAnchor:topContentView.trailingAnchor].active = YES;
        
        UIView *bottomContainerView = [[UIView alloc] init];
        bottomContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:bottomContainerView];
        [bottomContainerView.topAnchor constraintEqualToAnchor:topContainerView.bottomAnchor].active = YES;
        [bottomContainerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
        [bottomContainerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
        [bottomContainerView.heightAnchor constraintEqualToConstant:[self bottomContentHeight]].active = YES;
        
        UIView *bottomContentView = [[UIView alloc] init];
        bottomContentView.translatesAutoresizingMaskIntoConstraints = NO;
        [bottomContainerView addSubview:bottomContentView];
        [bottomContentView.topAnchor constraintGreaterThanOrEqualToAnchor:bottomContainerView.topAnchor constant:p].active = YES;
        [bottomContentView.leadingAnchor constraintEqualToAnchor:bottomContainerView.leadingAnchor constant:p].active = YES;
        [bottomContentView.bottomAnchor constraintLessThanOrEqualToAnchor:bottomContainerView.bottomAnchor constant:-p].active = YES;
        [bottomContentView.trailingAnchor constraintEqualToAnchor:bottomContainerView.trailingAnchor constant:-p].active = YES;
        [bottomContentView.centerYAnchor constraintEqualToAnchor:bottomContainerView.centerYAnchor].active = YES;
        
        _productImageView = ({
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            [bottomContentView addSubview:imageView];
            [imageView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
            [imageView.topAnchor constraintGreaterThanOrEqualToAnchor:bottomContentView.topAnchor].active = YES;
            [imageView.leadingAnchor constraintEqualToAnchor:bottomContentView.leadingAnchor].active = YES;
            [imageView.widthAnchor constraintEqualToConstant:104.f].active = YES;
            [imageView.heightAnchor constraintEqualToAnchor:imageView.widthAnchor].active = YES;
            imageView;
        });
        
        _productBrandLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.textAlignment = NSTextAlignmentCenter;
            label.minimumScaleFactor = .7f;
            label.adjustsFontSizeToFitWidth = YES;
            label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            [bottomContentView addSubview:label];
            [label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            [label.topAnchor constraintEqualToAnchor:self.productImageView.bottomAnchor constant:2.f].active = YES;
            [label.leadingAnchor constraintEqualToAnchor:self.productImageView.leadingAnchor].active = YES;
            [label.trailingAnchor constraintEqualToAnchor:self.productImageView.trailingAnchor].active = YES;
            label;
        });
        
        _productPriceLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor softTextColor];
            label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            [bottomContentView addSubview:label];
            [label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            [label.topAnchor constraintEqualToAnchor:self.productBrandLabel.bottomAnchor constant:2.f].active = YES;
            [label.leadingAnchor constraintEqualToAnchor:self.productImageView.leadingAnchor].active = YES;
            [label.bottomAnchor constraintLessThanOrEqualToAnchor:bottomContentView.bottomAnchor].active = YES;
            [label.trailingAnchor constraintEqualToAnchor:self.productImageView.trailingAnchor].active = YES;
            label;
        });
        
        UIImageView *favoriteImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"FavoriteHeartEmpty"]];
        favoriteImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.productImageView addSubview:favoriteImageView];
        [favoriteImageView.topAnchor constraintEqualToAnchor:self.productImageView.topAnchor].active = YES;
        [favoriteImageView.trailingAnchor constraintEqualToAnchor:self.productImageView.trailingAnchor].active = YES;
        
        UILabel *favoriteLabel = [[UILabel alloc] init];
        favoriteLabel.translatesAutoresizingMaskIntoConstraints = NO;
        favoriteLabel.text = @"Favorite";
        favoriteLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        [bottomContentView addSubview:favoriteLabel];
        [favoriteLabel.leadingAnchor constraintEqualToAnchor:self.productImageView.trailingAnchor constant:25.f].active = YES;
        [favoriteLabel.trailingAnchor constraintEqualToAnchor:bottomContentView.trailingAnchor].active = YES;
        [favoriteLabel.centerYAnchor constraintEqualToAnchor:favoriteImageView.centerYAnchor].active = YES;
        
        UIView *favoritePointerView = [self pointerView];
        favoritePointerView.translatesAutoresizingMaskIntoConstraints = NO;
        [bottomContentView addSubview:favoritePointerView];
        [favoritePointerView.leadingAnchor constraintEqualToAnchor:self.productImageView.trailingAnchor constant:-4.f].active = YES;
        [favoritePointerView.centerYAnchor constraintEqualToAnchor:favoriteLabel.centerYAnchor].active = YES;
        [favoritePointerView.trailingAnchor constraintEqualToAnchor:favoriteLabel.leadingAnchor constant:-4.f].active = YES;
        
        UILabel *purchaseLabel = [[UILabel alloc] init];
        purchaseLabel.translatesAutoresizingMaskIntoConstraints = NO;
        purchaseLabel.text = @"Tap to purchase";
        purchaseLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        [bottomContentView addSubview:purchaseLabel];
        [purchaseLabel.leadingAnchor constraintEqualToAnchor:favoriteLabel.leadingAnchor].active = YES;
        [purchaseLabel.trailingAnchor constraintEqualToAnchor:bottomContentView.trailingAnchor].active = YES;
        [purchaseLabel.centerYAnchor constraintEqualToAnchor:bottomContentView.centerYAnchor].active = YES;
        
        UIView *purchasePointerView = [self pointerView];
        purchasePointerView.translatesAutoresizingMaskIntoConstraints = NO;
        [bottomContentView addSubview:purchasePointerView];
        [purchasePointerView.leadingAnchor constraintEqualToAnchor:self.productImageView.trailingAnchor constant:-25.f].active = YES;
        [purchasePointerView.centerYAnchor constraintEqualToAnchor:purchaseLabel.centerYAnchor].active = YES;
        [purchasePointerView.trailingAnchor constraintEqualToAnchor:purchaseLabel.leadingAnchor constant:-4.f].active = YES;
        
        _button = ({
            Button *button = [Button buttonWithType:UIButtonTypeCustom];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            [button setTitle:@"Got It" forState:UIControlStateNormal];
            button.layer.cornerRadius = 0.f;
            [self addSubview:button];
            [button.topAnchor constraintEqualToAnchor:bottomContainerView.bottomAnchor].active = YES;
            [button.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
            [button.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
            [button.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
            button;
        });
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    CGFloat height = [self topContentHeight] + [self bottomContentHeight] + self.button.intrinsicContentSize.height;
    return CGSizeMake(UIViewNoIntrinsicMetric, height);
}

- (CGFloat)topContentHeight {
    return 140.f;
}

- (CGFloat)bottomContentHeight {
    return 210.f;
}

- (UIView *)pointerView {
    UIView *view = [[UIView alloc] init];
    
    CGFloat circleDiameter = 5.f;
    
    UIView *circle = [[UIView alloc] init];
    circle.translatesAutoresizingMaskIntoConstraints = NO;
    circle.backgroundColor = [UIColor crazeRedColor];
    circle.layer.cornerRadius = circleDiameter / 2.f;
    circle.layer.masksToBounds = YES;
    [view addSubview:circle];
    [circle setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [circle.widthAnchor constraintEqualToConstant:circleDiameter].active = YES;
    [circle.heightAnchor constraintEqualToAnchor:circle.widthAnchor].active = YES;
    [circle.leadingAnchor constraintEqualToAnchor:view.leadingAnchor].active = YES;
    [circle.centerYAnchor constraintEqualToAnchor:view.centerYAnchor].active = YES;
    
    UIView *line = [[UIView alloc] init];
    line.translatesAutoresizingMaskIntoConstraints = NO;
    line.backgroundColor = [UIColor crazeRedColor];
    [view addSubview:line];
    [line setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [line.heightAnchor constraintEqualToConstant:1.f].active = YES;
    [line.leadingAnchor constraintEqualToAnchor:circle.centerXAnchor].active = YES;
    [line.trailingAnchor constraintEqualToAnchor:view.trailingAnchor].active = YES;
    [line.centerYAnchor constraintEqualToAnchor:view.centerYAnchor].active = YES;
    
    return view;
}

@end

@implementation TutorialProductsPageViewController
@dynamic view;

- (void)loadView {
    self.view = [[ProductsPageHelperView alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
    
    [self.view.productImageView sd_setImageWithURL:[NSURL URLWithString:self.product.imageURL] placeholderImage:[UIImage imageNamed:@"DefaultProduct"] options:SDWebImageRetryFailed | SDWebImageHighPriority];
    self.view.productBrandLabel.text = self.product.brand.length ? self.product.brand : self.product.merchant;
    self.view.productPriceLabel.text = self.product.price;
    [self.view.button addTarget:self action:@selector(dismissViewController) forControlEvents:UIControlEventTouchUpInside];
}

- (void)dismissViewController {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
