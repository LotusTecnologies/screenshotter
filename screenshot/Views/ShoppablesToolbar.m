//
//  ShoppablesToolbar.m
//  screenshot
//
//  Created by Corey Werner on 8/13/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ShoppablesToolbar.h"
#import "screenshot-Swift.h"
#import "ScreenshotImageFetcher.h"
#import "UIColor+Appearance.h"
#import "Geometry.h"

@interface ShoppablesToolbar ()

@property (nonatomic, strong) UIView *shoppablesContainerView;
@property (nonatomic, strong) NSArray<UIButton *> *shoppableButtons;
@property (nonatomic) NSUInteger selectedShoppableButtonIndex;

@end

@implementation ShoppablesToolbar
@dynamic delegate;

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _shoppablesContainerView = ({
            UIView *view = [[UIView alloc] init];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:view];
            [view.topAnchor constraintEqualToAnchor:self.layoutMarginsGuide.topAnchor].active = YES;
            [view.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.layoutMarginsGuide.leadingAnchor].active = YES;
            [view.bottomAnchor constraintEqualToAnchor:self.layoutMarginsGuide.bottomAnchor].active = YES;
            [view.trailingAnchor constraintLessThanOrEqualToAnchor:self.layoutMarginsGuide.trailingAnchor].active = YES;
            [view.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
            view;
        });
    }
    return self;
}


#pragma mark - Shoppable

- (void)insertShoppables:(NSArray<Shoppable *> *)shoppables withScreenshot:(Screenshot *)screenshot {
    [self.shoppableButtons performSelector:@selector(removeFromSuperview)];
    self.shoppableButtons = nil;
    
    if (shoppables && shoppables.count && screenshot) {
        [ScreenshotImageFetcher screenshot:screenshot handler:^(UIImage *image, Screenshot *screenshot) {
            NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
            
            for (NSUInteger i = 0; i < shoppables.count; i++) {
                Shoppable *shoppable = shoppables[i];
                
                if (shoppable) {
                    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                    button.translatesAutoresizingMaskIntoConstraints = NO;
                    button.backgroundColor = [UIColor whiteColor];
                    [button setImage:[shoppable croppedWithImage:image] forState:UIControlStateNormal];
                    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
                    button.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
                    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
                    button.adjustsImageWhenHighlighted = NO;
                    button.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, 0.f, -[Geometry padding]);
                    [button addTarget:self action:@selector(shoppableButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                    button.layer.borderColor = [self shoppableButtonBorderColor].CGColor;
                    button.layer.borderWidth = 1.f;
                    [self.shoppablesContainerView addSubview:button];
                    [button.topAnchor constraintEqualToAnchor:self.shoppablesContainerView.topAnchor].active = YES;
                    [button.bottomAnchor constraintEqualToAnchor:self.shoppablesContainerView.bottomAnchor].active = YES;
                    [button.widthAnchor constraintEqualToAnchor:button.heightAnchor multiplier:.8f].active = YES;
                    
                    if (i == 0) {
                        [button.leadingAnchor constraintEqualToAnchor:self.shoppablesContainerView.leadingAnchor].active = YES;
                        
                    } else {
                        UIButton *previousButton = [buttons objectAtIndex:i - 1];
                        
                        [button.leadingAnchor constraintEqualToAnchor:previousButton.layoutMarginsGuide.trailingAnchor].active = YES;
                    }
                    
                    if (i == shoppables.count - 1) {
                        [button.trailingAnchor constraintEqualToAnchor:self.shoppablesContainerView.trailingAnchor].active = YES;
                    }
                    
                    [buttons addObject:button];
                }
            }
            
            self.shoppableButtons = buttons;
            [self selectShoppableButtonAtIndex:0];
        }];
    }
}

- (void)shoppableButtonAction:(UIButton *)button {
    NSUInteger index = [self.shoppableButtons indexOfObject:button];
    
    [self deselectShoppableButtonAtIndex:self.selectedShoppableButtonIndex];
    [self selectShoppableButtonAtIndex:index];
    [self.delegate shoppablesToolbar:self didSelectShoppableAtIndex:index];
}

- (void)selectShoppableButtonAtIndex:(NSUInteger)index {
    UIButton *button = self.shoppableButtons[index];
    button.layer.borderColor = [UIColor crazeRedColor].CGColor;
    
    self.selectedShoppableButtonIndex = index;
}

- (void)deselectShoppableButtonAtIndex:(NSUInteger)index {
    UIButton *button = self.shoppableButtons[index];
    button.layer.borderColor = [self shoppableButtonBorderColor].CGColor;
}

- (UIColor *)shoppableButtonBorderColor {
    return [UIColor colorWithWhite:193.f/255.f alpha:1.f];
}

@end
