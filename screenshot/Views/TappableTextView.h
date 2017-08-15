//
//  TappableTextView.h
//  screenshot
//
//  Created by Corey Werner on 8/15/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TappableTextView;

@protocol TappableTextViewDelegate <UITextViewDelegate>
@optional

//  The index is from the order used with -applyTappableText:
- (void)tappableTextView:(TappableTextView *)textView tappedTextAtIndex:(NSUInteger)index;

@end

@interface TappableTextView : UITextView

@property (nonatomic, weak) id<TappableTextViewDelegate> delegate;

//  This will set the attributedText property. The dictionary's
//  string is a text fragment while the number is a boolean. If
//  @YES then the text fragment becomes tappable.
- (void)applyTappableText:(NSArray<NSDictionary<NSString *, NSNumber *> *> *)texts;
- (void)applyTappableText:(NSArray<NSDictionary<NSString *, NSNumber *> *> *)texts withAttributes:(NSDictionary<NSString *, id> *)attributes;

@end
