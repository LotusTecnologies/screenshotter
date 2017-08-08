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
                       CGRect viewBounds = self.view.bounds;
                       UIImageView *imageView = [[UIImageView alloc] initWithFrame:viewBounds];
                       imageView.image = matchModel.lastScreenshot;
                       [self.view addSubview:imageView];
                       NSString *uploadedURLString = [[responseObject allKeys] firstObject];
                       NSArray *shoppables = responseObject[uploadedURLString];
                       for (NSDictionary *shoppable in shoppables) {
                           NSArray *b0 = shoppable[@"b0"];
                           NSArray *b1 = shoppable[@"b1"];
                           NSNumber *nb0x = b0[0];
                           NSNumber *nb0y = b0[1];
                           NSNumber *nb1x = b1[0];
                           NSNumber *nb1y = b1[1];
                           double b0x = [nb0x doubleValue];
                           double b0y = [nb0y doubleValue];
                           double b1x = [nb1x doubleValue];
                           double b1y = [nb1y doubleValue];
                           CGFloat viewWidth = viewBounds.size.width;
                           CGFloat viewHeight = viewBounds.size.height;
                           NSLog(@"b0:%@", b0);
                           NSLog(@"b1:%@", b1);
                           NSLog(@"nb0x:%@  nb0y:%@  nb1x:%@  nb1y:%@", nb0x, nb0y, nb1x, nb1y);
                           NSLog(@"b0x:%f  b0y:%f  b1x:%f  b1y:%f", b0x, b0y, b1x, b1y);
                           CGRect frame = CGRectMake(b0x * viewWidth, b0y * viewHeight, (b1x - b0x) * viewWidth, (b1y - b0y) * viewHeight);
                           NSLog(@"frame:%@", NSStringFromCGRect(frame));
                           UIView *shoppableView = [[UIView alloc] initWithFrame:frame];
                           shoppableView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.20];
                           shoppableView.layer.borderWidth = 1.0f;
                           shoppableView.layer.borderColor = [[UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:1.0f] CGColor];
                           [imageView addSubview:shoppableView];
                       }
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
