//
//  ViewController.m
//  screenshot
//
//  Created by Gershon Kagan on 6/28/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ViewController.h"
#import "MatchModel.h"
#import "MainTabBarController.h"
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
    
    NSMutableString *logString = [[NSMutableString alloc] initWithString:@""];
    MatchModel *matchModel = [MatchModel shared];
    [matchModel logClarifaiSyteInitial:logString
               completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                   if (error) {
                       [logString appendFormat:@"logClarifaiSyteInitial error:%@", error];
                   } else {
                       [logString appendFormat:@"logClarifaiSyteInitial response:%@\nresponseObject:%@", response, responseObject];
                   }
                   [self finishWithText:logString hideOpen:YES];
               }
     ];
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
    MainTabBarController *tabBarController = [[MainTabBarController alloc] init];
    
    [self presentViewController:tabBarController animated:YES completion:nil];
}

@end
