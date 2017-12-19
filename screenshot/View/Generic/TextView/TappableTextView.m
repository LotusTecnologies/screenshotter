//
//  TappableTextView.m
//  screenshot
//
//  Created by Corey Werner on 8/15/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TappableTextView.h"
#import "screenshot-Swift.h"

@interface TappableTextView ()

@property (nonatomic, strong) NSArray<NSNumber *> *tappableIndexes;

@end

@implementation TappableTextView
@dynamic delegate;

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        UITapGestureRecognizer *tappableTextGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappableTextGestureRecognizerAction:)];
        [self addGestureRecognizer:tappableTextGestureRecognizer];
    }
    return self;
}

- (void)applyTappableText:(NSArray<NSDictionary<NSString *, NSNumber *> *> *)texts {
    [self applyTappableText:texts withAttributes:nil];
}

- (void)applyTappableText:(NSArray<NSDictionary<NSString *, NSNumber *> *> *)texts withAttributes:(NSDictionary<NSString *, id> *)attributes {
    NSMutableArray *tappableIndexes = [NSMutableArray array];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    for (NSUInteger i = 0; i < texts.count; i++) {
        NSDictionary *dictionary = texts[i];
        NSString *text = [[dictionary allKeys] firstObject];
        BOOL isTappable = [[[dictionary allValues] firstObject] boolValue];
        NSDictionary *fragmentAttributes;
        
        if (isTappable) {
            [tappableIndexes addObject:@(i)];
            fragmentAttributes = @{[NSString stringWithFormat:@"%lu", (unsigned long)i]: @(isTappable),
                                   NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                   NSUnderlineColorAttributeName: [UIColor gray7]
                                   };
        }
        
        NSAttributedString *fragmentAttributedString = [[NSAttributedString alloc] initWithString:text attributes:fragmentAttributes];
        [attributedString appendAttributedString:fragmentAttributedString];
    }
    
    if (attributes) {
        [attributedString addAttributes:attributes range:NSMakeRange(0, attributedString.length)];
    }
    
    self.tappableIndexes = tappableIndexes;
    self.attributedText = attributedString;
}

- (void)tappableTextGestureRecognizerAction:(UITapGestureRecognizer *)tapGestureRecognizer {
    if ([self.delegate respondsToSelector:@selector(tappableTextView:tappedTextAtIndex:)]) {
        CGPoint location = [tapGestureRecognizer locationInView:self];
        location.x -= self.textContainerInset.left;
        location.y -= self.textContainerInset.top;
        
        NSUInteger characterIndex = [self.layoutManager characterIndexForPoint:location inTextContainer:self.textContainer fractionOfDistanceBetweenInsertionPoints:NULL];
        
        if (self.textStorage.length > characterIndex) {
            for (NSNumber *tappableNumber in self.tappableIndexes) {
                NSString *tappableIndexString = [NSString stringWithFormat:@"%@", tappableNumber];
                
                if ([self.attributedText attribute:tappableIndexString atIndex:characterIndex effectiveRange:NULL]) {
                    [self.delegate tappableTextView:self tappedTextAtIndex:[tappableNumber unsignedIntegerValue]];
                    break;
                }
            }
        }
    }
}

@end
