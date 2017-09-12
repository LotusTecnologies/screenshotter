//
//  InfoCollectionViewCell.h
//  screenshot
//
//  Created by Corey Werner on 9/11/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, InfoCollectionViewCellType) {
    InfoCollectionViewCellTypeNoShoppables,
    InfoCollectionViewCellTypeNoFashion
};

@interface InfoCollectionViewCell : UICollectionViewCell

@property (nonatomic) InfoCollectionViewCellType type;

@property (nonatomic, strong, readonly) UIButton *closeButton;
@property (nonatomic, strong, readonly) UIButton *continueButton;

@end
