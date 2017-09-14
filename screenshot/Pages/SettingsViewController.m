//
//  SettingsViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "SettingsViewController.h"
#import "TutorialViewController.h"
#import "Geometry.h"
#import "PermissionsManager.h"
#import "UIApplication+Version.h"
#import "WebViewController.h"
#import "screenshot-Swift.h"

@import MessageUI;

typedef NS_ENUM(NSUInteger, SectionType) {
    // Order reflects in the TableView
    SectionTypePermissions,
    SectionTypeEmail,
    SectionTypeAbout
};

typedef NS_ENUM(NSUInteger, RowType) {
    RowTypeCameraRoll,
    RowTypePushNotification,
    RowTypeLocationService,
    RowTypeEmail,
    RowTypeTutorial,
    RowTypeTellFriend,
    RowTypeContactUs,
    RowTypeBug,
    RowTypeVersion
};

@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, TutorialViewControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *data;

@end

@implementation SettingsViewController

#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        self.title = @"Settings";
        [self addNavigationItemLogo];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *tableHeaderContentView;
    UIView *tableHeaderView = ({
        CGFloat p = [Geometry padding];
        
        UIView *view = [[UIView alloc] init];
        view.layoutMargins = UIEdgeInsetsMake(p, p, 0.f, p);
        
        tableHeaderContentView = [[UIView alloc] init];
        tableHeaderContentView.translatesAutoresizingMaskIntoConstraints = NO;
        tableHeaderContentView.backgroundColor = [UIColor whiteColor];
        tableHeaderContentView.layoutMargins = UIEdgeInsetsMake(p, p, p, p);
        tableHeaderContentView.layer.cornerRadius = 10.f;
        tableHeaderContentView.layer.shadowColor = [UIColor blackColor].CGColor;
        tableHeaderContentView.layer.shadowOffset = CGSizeMake(0.f, 1.f);
        tableHeaderContentView.layer.shadowRadius = 1.f;
        tableHeaderContentView.layer.shadowOpacity = .3f;
        [view addSubview:tableHeaderContentView];
        [tableHeaderContentView.topAnchor constraintEqualToAnchor:view.layoutMarginsGuide.topAnchor].active = YES;
        [tableHeaderContentView.bottomAnchor constraintEqualToAnchor:view.layoutMarginsGuide.bottomAnchor].active = YES;
        [tableHeaderContentView.centerXAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
        [tableHeaderContentView.leftAnchor constraintGreaterThanOrEqualToAnchor:view.layoutMarginsGuide.leftAnchor].active = YES;
        [tableHeaderContentView.rightAnchor constraintLessThanOrEqualToAnchor:view.layoutMarginsGuide.rightAnchor].active = YES;
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SettingsScreenshot"]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, 0.f, -p);
        [tableHeaderContentView addSubview:imageView];
        [imageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [imageView.topAnchor constraintEqualToAnchor:tableHeaderContentView.layoutMarginsGuide.topAnchor].active = YES;
        [imageView.leftAnchor constraintEqualToAnchor:tableHeaderContentView.layoutMarginsGuide.leftAnchor].active = YES;
        [imageView.bottomAnchor constraintEqualToAnchor:tableHeaderContentView.layoutMarginsGuide.bottomAnchor].active = YES;
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        NSUInteger screenshotCount = 2; // TODO: @Gershon update this value
        NSString *numberString = [formatter stringFromNumber:@(screenshotCount)];
        NSString *sString = (screenshotCount == 1) ? @"" : @"s";
        NSString *labelText = [NSString stringWithFormat:@"%@ screenshot%@", numberString, sString];
        
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.textAlignment = NSTextAlignmentCenter;
        label.text = labelText;
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = .7f;
        [tableHeaderContentView addSubview:label];
        [label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [label.topAnchor constraintEqualToAnchor:tableHeaderContentView.layoutMarginsGuide.topAnchor].active = YES;
        [label.leftAnchor constraintEqualToAnchor:imageView.layoutMarginsGuide.rightAnchor].active = YES;
        [label.bottomAnchor constraintEqualToAnchor:tableHeaderContentView.layoutMarginsGuide.bottomAnchor].active = YES;
        [label.rightAnchor constraintEqualToAnchor:tableHeaderContentView.layoutMarginsGuide.rightAnchor].active = YES;
        
        CGRect rect = view.frame;
        rect.size.height = view.layoutMargins.top + view.layoutMargins.bottom + tableHeaderContentView.layoutMargins.top + tableHeaderContentView.layoutMargins.bottom + imageView.image.size.height;
        view.frame = rect;
        view;
    });
    
    UITextView *tableFooterTextView = ({
        UITextView *textView = [[UITextView alloc] init];
        textView.backgroundColor = [UIColor clearColor];
        textView.editable = NO;
        textView.scrollsToTop = NO;
        textView.scrollEnabled = NO;
        textView.dataDetectorTypes = UIDataDetectorTypePhoneNumber | UIDataDetectorTypeLink;
        textView.textAlignment = NSTextAlignmentCenter;
        textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        textView.text = @"Questions? Get in touch: (212) 202-0991\nOr info@crazeapp.com";
        [textView sizeToFit];
        textView.frame = ({
            CGRect rect = textView.frame;
            rect.size.height += [Geometry padding];
            rect;
        });
        textView;
    });
    
    self.tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.translatesAutoresizingMaskIntoConstraints = NO;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundView = nil;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.tableHeaderView = tableHeaderView;
        tableView.tableFooterView = tableFooterTextView;
        [self.view addSubview:tableView];
        [tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        [tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
        [tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        tableView;
    });
    
    [tableHeaderContentView layoutIfNeeded];
    tableHeaderContentView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:tableHeaderContentView.bounds cornerRadius:tableHeaderContentView.layer.cornerRadius].CGPath;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableView.contentOffset = CGPointMake(0.f, -self.tableView.contentInset.top);
    
    [self reloadPermissionIndexPaths];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.view.window) {
        [self reloadPermissionIndexPaths];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}


#pragma mark - Data

- (NSDictionary *)dataDict {
    return @{@(SectionTypePermissions): @[@(RowTypeCameraRoll),
                                          @(RowTypePushNotification),
//                                          @(RowTypeLocationService)
                                          ],
             @(SectionTypeEmail): @[@(RowTypeEmail)
                                    ],
             @(SectionTypeAbout): @[@(RowTypeTutorial),
                                    @(RowTypeTellFriend),
                                    @(RowTypeContactUs),
                                    @(RowTypeBug),
                                    @(RowTypeVersion)
                                    ]
             };
}

- (NSArray *)data {
    if (!_data) {
        NSDictionary *dict = [self dataDict];
        
        _data = @[[dict objectForKey:@(SectionTypePermissions)],
                  [dict objectForKey:@(SectionTypeEmail)],
                  [dict objectForKey:@(SectionTypeAbout)]];
    }
    return _data;
}

- (RowType)rowTypeForIndexPath:(NSIndexPath *)indexPath {
    return [self.data[indexPath.section][indexPath.row] integerValue];
}

- (NSIndexPath *)indexPathForRowType:(RowType)rowType inSectionType:(SectionType)sectionType {
    NSInteger row = [[self dataDict][@(sectionType)] indexOfObject:@(rowType)];
    
    return [NSIndexPath indexPathForRow:row inSection:sectionType];
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self textForSectionType:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    RowType rowType = [self rowTypeForIndexPath:indexPath];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.text = [self textForRowType:rowType];
    cell.detailTextLabel.text = [self detailTextForRowType:rowType];
    cell.accessoryType = [self accessoryTypeForRowType:rowType];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    RowType rowType = [self rowTypeForIndexPath:indexPath];
    
    switch (rowType) {
        case RowTypeVersion:
        case RowTypeEmail:
            return NO;
            break;
        case RowTypeLocationService:
        case RowTypePushNotification:
        case RowTypeCameraRoll:
            return ![[PermissionsManager sharedPermissionsManager] hasPermissionForType:[self permissionTypeForRowType:rowType]];
            break;
        default:
            return YES;
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RowType rowType = [self rowTypeForIndexPath:indexPath];
    
    switch (rowType) {
        case RowTypeBug:
            [self presentMailComposer];
            break;
        case RowTypeTellFriend: {
            NSString *text = @"Download CRAZE, the app that lets you shop any screenshot, for free! https://crazeapp.com/app/";
            UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[text] applicationActivities:nil];
            activityViewController.popoverPresentationController.sourceView = self.view;
            [self presentViewController:activityViewController animated:YES completion:nil];
        }
            break;
        case RowTypeTutorial: {
            TutorialViewController *viewController = [[TutorialViewController alloc] init];
            viewController.delegate = self;
            [self.navigationController pushViewController:viewController animated:YES];
        }
            break;
        case RowTypeEmail:
            break;
        case RowTypeContactUs:
            [IntercomHelper.sharedInstance presentMessagingUI];
            break;
        case RowTypeLocationService:
        case RowTypePushNotification:
        case RowTypeCameraRoll: {
            [[PermissionsManager sharedPermissionsManager] requestPermissionForType:[self permissionTypeForRowType:rowType] openSettingsIfNeeded:YES response:^(BOOL granted) {
                if (granted) {
                    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                }
            }];
        }
            break;
        case RowTypeVersion:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)textForSectionType:(SectionType)sectionType {
    switch (sectionType) {
        case SectionTypePermissions:
            return @"Permissions";
            break;
        case SectionTypeAbout:
            return @"About";
            break;
        case SectionTypeEmail:
            return @"Email";
            break;
    }
}

- (NSString *)textForRowType:(RowType)rowType {
    switch (rowType) {
        case RowTypeBug:
            return @"Submit a Bug";
            break;
        case RowTypeTellFriend:
            return @"Tell a Friend";
            break;
        case RowTypeContactUs:
            return @"Contact Us";
            break;
        case RowTypeTutorial:
            return @"Replay Tutorial";
            break;
        case RowTypeEmail:
            return [[NSUserDefaults standardUserDefaults] valueForKey:UserDefaultsKeys.email];
            break;
        case RowTypeLocationService:
            return @"Location Services";
            break;
        case RowTypePushNotification:
            return @"Push Notifications";
            break;
        case RowTypeCameraRoll:
            return @"Camera Roll";
            break;
        case RowTypeVersion:
            return @"App Version";
            break;
    }
}

- (NSString *)detailTextForRowType:(RowType)rowType {
    switch (rowType) {
        case RowTypeCameraRoll:
        case RowTypeLocationService:
        case RowTypePushNotification:
            return [self enabledTextForRowType:rowType];
            break;
        case RowTypeVersion:
            return [NSString stringWithFormat:@"%@%@", [UIApplication versionBuild], Constants.buildEnvironmentSuffix];
            break;
        default:
            return nil;
            break;
    }
}

- (NSString *)enabledTextForRowType:(RowType)rowType {
    return [[PermissionsManager sharedPermissionsManager] hasPermissionForType:[self permissionTypeForRowType:rowType]] ? @"Enabled" : @"Disabled";
}

- (UITableViewCellAccessoryType)accessoryTypeForRowType:(RowType)rowType {
    switch (rowType) {
        case RowTypeTutorial:
        case RowTypeBug:
            return UITableViewCellAccessoryDisclosureIndicator;
            break;
        default:
            return UITableViewCellAccessoryNone;
            break;
    }
}

- (void)reloadPermissionIndexPaths {
    NSMutableArray *permissionIndexPaths = [NSMutableArray array];
    NSInteger section = SectionTypePermissions;
    
    for (NSNumber *permissionNumber in [self dataDict][@(section)]) {
        [permissionIndexPaths addObject:[NSIndexPath indexPathForRow:[permissionNumber integerValue] inSection:section]];
    }
    
    [self.tableView reloadRowsAtIndexPaths:permissionIndexPaths withRowAnimation:UITableViewRowAnimationFade];
}


#pragma mark - Permissions

- (PermissionType)permissionTypeForRowType:(RowType)rowType {
    switch (rowType) {
        case RowTypeCameraRoll:
            return PermissionTypePhoto;
            break;
        case RowTypeLocationService:
            return PermissionTypeLocation;
            break;
        case RowTypePushNotification:
        default:
            return PermissionTypePush;
            break;
    }
}


#pragma mark - Tutorial

- (void)tutorialViewControllerDidComplete:(TutorialViewController *)viewController {
    NSIndexPath *indexPath = [self indexPathForRowType:RowTypeEmail inSectionType:SectionTypeEmail];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Mail

- (void)presentMailComposer {
    if ([MFMailComposeViewController canSendMail]) {
        NSArray *message = @[@"\n\n\n",
                             @"-----------------",
                             @"Don't edit below.\n",
                             [NSString stringWithFormat:@"version: %@", [UIApplication versionBuild]]
                             ];
        
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        mail.mailComposeDelegate = self;
        [mail setSubject:@"Bug Report"];
        [mail setMessageBody:[message componentsJoinedByString:@"\n"] isHTML:NO];
        [mail setToRecipients:@[@"support@crazeapp.com"]];
        
        [self presentViewController:mail animated:YES completion:nil];
        
    } else {
        NSURL* mailURL = [NSURL URLWithString:@"message://"];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Setup Email" message:@"You need to setup an email on your device in order to send a bug report." preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Later" style:UIAlertActionStyleCancel handler:nil]];
        
        if ([[UIApplication sharedApplication] canOpenURL:mailURL]) {
            [alertController addAction:[UIAlertAction actionWithTitle:@"Setup" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[UIApplication sharedApplication] openURL:mailURL options:@{} completionHandler:nil];
            }]];
        }
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
