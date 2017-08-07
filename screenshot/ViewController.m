//
//  ViewController.m
//  screenshot
//
//  Created by Gershon Kagan on 6/28/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ViewController.h"
#import "MatchModel.h"
#import "MainNavigationController.h"
@import MobileCoreServices;

NSString *imageMediaType;

@interface ViewController ()

@property(weak, nonatomic) IBOutlet UIButton *openURLButton;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(weak, nonatomic) IBOutlet UILabel *resultantJsonLabel;
@property(weak, nonatomic) IBOutlet UIButton *openButton;

@property(strong, nonatomic) NSString *topMediaURLString;

@end


@implementation ViewController

// MARK: - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    imageMediaType = (NSString *)kUTTypeImage;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadLastScreenshot) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [self.openButton addTarget:self action:@selector(openButtonClick) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self uploadLastScreenshot];
}

-(void)uploadLastScreenshot {
    self.topMediaURLString = nil;
    self.openURLButton.hidden = YES;
    _resultantJsonLabel.text = nil;
    [_activityIndicator startAnimating];
    MatchModel *matchModel = [MatchModel shared];
    [matchModel latestScreenshotWithCallback:^(UIImage *pickedImage) {
        if (pickedImage == nil) {
            [self finishWithText:@"ERROR latestScreenshotWithCallback returned nothing" hideOpen:YES];
        } else {
            _resultantJsonLabel.text = [NSString stringWithFormat:@"image size:%@  scale:%.1f\n", NSStringFromCGSize(pickedImage.size), pickedImage.scale];
            [matchModel isFashion:pickedImage completion:^(NSArray<ClarifaiOutput *> *outputs, NSError *error) {
                BOOL isFashion = NO;
                NSInteger j = 0;
                NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:1024];
                [outputString setString:_resultantJsonLabel.text];
                for (ClarifaiOutput *output in outputs) {
                    for (ClarifaiConcept *concept in output.concepts) {
                        if (   [concept.conceptName isEqualToString:@"woman"]
                            || [concept.conceptName isEqualToString:@"fashion"]
                            || [concept.conceptName isEqualToString:@"beauty"]) {
                            isFashion = YES;
                        }
                        [outputString appendFormat:@"%.2ld  %f  %@\n", (long)++j, concept.score * 100.0f, concept.conceptName];
                    }
                }
                [outputString appendFormat:@"isFashion:%@\n", (isFashion ? @"YES" : @"NO")];
                [self finishWithText:outputString hideOpen:YES];
            }];
        }
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)openButtonClick {
    MainNavigationController *navController = [[MainNavigationController alloc] init];
    
    [self presentViewController:navController animated:YES completion:nil];
}

@end
