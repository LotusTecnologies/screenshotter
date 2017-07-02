//
//  ViewController.m
//  screenshot
//
//  Created by Gershon Kagan on 6/28/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ViewController.h"
#import "MatchModel.h"
@import MobileCoreServices;

NSString *imageMediaType;

@interface ViewController ()

@property(weak, nonatomic) IBOutlet UIButton *openURLButton;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(weak, nonatomic) IBOutlet UILabel *resultantJsonLabel;

@property(strong, nonatomic) NSString *topMediaURLString;

@end


@implementation ViewController

// MARK: - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    imageMediaType = (NSString *)kUTTypeImage;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.topMediaURLString = nil;
    self.openURLButton.hidden = YES;
    [_activityIndicator startAnimating];
    MatchModel *matchModel = [MatchModel shared];
    [matchModel latestScreenshotWithCallback:^(UIImage *pickedImage) {
        if (pickedImage == nil) {
            [self finishWithText:@"ERROR latestScreenshotWithCallback returned nothing" hideOpen:YES];
        } else {
            _resultantJsonLabel.text = [NSString stringWithFormat:@"image size:%@  scale:%.1f\n", NSStringFromCGSize(pickedImage.size), pickedImage.scale];
            [matchModel matchImage:pickedImage completion:^(NSArray<ClarifaiSearchResult *> *results, NSError *error) {
                ClarifaiSearchResult *topResult = results.firstObject;
                if (topResult && topResult.mediaURL) {
                    self.topMediaURLString = topResult.mediaURL;
                } else {
                    self.topMediaURLString = nil;
                }
                NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:1024];
                [outputString setString:_resultantJsonLabel.text];
                [outputString appendFormat:@"%@\nerror:%@\nresults:%@\n", _resultantJsonLabel.text, error, results];
                for (ClarifaiSearchResult *searchResult in results) {
                    [outputString appendFormat:@"score:%@  inputID:%@  concepts:%@  mediaURL:%@  creationDate:%@  mediaData:%@  location:%@  metadata:%@\n", searchResult.score, searchResult.inputID, searchResult.concepts, searchResult.mediaURL, searchResult.creationDate, searchResult.mediaData, searchResult.location, searchResult.metadata];
                }
                [self finishWithText:outputString hideOpen:self.topMediaURLString == nil];
            }];
        }
    }];
}

// MARK: - Handlers

- (IBAction)openURL {
    if (_topMediaURLString.length) {
        UIApplication *application = [UIApplication sharedApplication];
        if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
            [application openURL:[NSURL URLWithString:_topMediaURLString] options:@{UIApplicationOpenURLOptionUniversalLinksOnly : @NO} completionHandler:nil];
        } else {
            [application openURL:[NSURL URLWithString:_topMediaURLString]];
        }
    }
}

// MARK: - Helper

- (void)finishWithText:(NSString *)text hideOpen:(BOOL)hideOpenButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        _openURLButton.hidden = hideOpenButton;
        [_activityIndicator stopAnimating];
        _resultantJsonLabel.text = text;
        NSLog(@"%@", text);
    });
}

@end
