//
//  SettingsViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "SettingsViewController.h"
#import "PermissionsManager.h"
#import "screenshot-Swift.h"

@import MessageUI;

typedef NS_ENUM(NSUInteger, SectionType) {
    // Order reflects in the TableView
    SectionTypeInfo,
    SectionTypePermissions,
    SectionTypeProducts,
    SectionTypeFollow,
    SectionTypeAbout
};

typedef NS_ENUM(NSUInteger, RowType) {
    RowTypePhotoPermission,
    RowTypePushPermission,
    RowTypeLocationPermission,
    RowTypeEmail,
    RowTypeName,
    RowTypeTutorialVideo,
    RowTypeTellFriend,
    RowTypeUsageStreak,
    RowTypeContactUs,
    RowTypeBug,
    RowTypeVersion,
    RowTypeCoins,
    RowTypeProductGender,
    RowTypeProductSize,
    RowTypeCurrency
};

@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MFMailComposeViewControllerDelegate, TutorialViewControllerDelegate, TutorialVideoViewControllerDelegate, ViewControllerLifeCycle>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *tableHeaderContentView;
@property (nonatomic, strong) UITextView *tableFooterTextView;
@property (nonatomic, strong) UIView *tableViewFollowSectionFooter;
@property (nonatomic, strong) UILabel *screenshotsCountLabel;
@property (nonatomic, strong) NSDictionary<NSNumber *, NSArray<NSNumber *> *> *data;

@property (nonatomic, strong) UITextField *nameTextField;
@property (nonatomic, strong) UITextField *emailTextField;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *previousTexts;

@end

@implementation SettingsViewController

#pragma mark - Life Cycle

- (NSString *)title {
    return @"Settings";
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        [self addNavigationItemLogo];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *tableHeaderView = ({
        CGFloat p = [Geometry padding];
        
        UIView *view = [[UIView alloc] init];
        view.layoutMargins = UIEdgeInsetsMake(p, p, 0.f, p);
        
        UIView *tableHeaderContentView = [[UIView alloc] init];
        tableHeaderContentView.translatesAutoresizingMaskIntoConstraints = NO;
        tableHeaderContentView.backgroundColor = [UIColor whiteColor];
        tableHeaderContentView.layoutMargins = UIEdgeInsetsMake(p, p, p, p);
        tableHeaderContentView.layer.cornerRadius = [Geometry defaultCornerRadius];
        tableHeaderContentView.layer.shadowColor = _Shadow.color.CGColor;
        tableHeaderContentView.layer.shadowOffset = _Shadow.offset;
        tableHeaderContentView.layer.shadowRadius = _Shadow.radius;
        tableHeaderContentView.layer.shadowOpacity = 1.f;
        [view addSubview:tableHeaderContentView];
        [tableHeaderContentView.topAnchor constraintEqualToAnchor:view.layoutMarginsGuide.topAnchor].active = YES;
        [tableHeaderContentView.bottomAnchor constraintEqualToAnchor:view.layoutMarginsGuide.bottomAnchor].active = YES;
        [tableHeaderContentView.centerXAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
        [tableHeaderContentView.leftAnchor constraintGreaterThanOrEqualToAnchor:view.layoutMarginsGuide.leftAnchor].active = YES;
        [tableHeaderContentView.rightAnchor constraintLessThanOrEqualToAnchor:view.layoutMarginsGuide.rightAnchor].active = YES;
        _tableHeaderContentView = tableHeaderContentView;
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SettingsAddPhotos"]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, 0.f, -p);
        [tableHeaderContentView addSubview:imageView];
        [imageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [imageView.topAnchor constraintEqualToAnchor:tableHeaderContentView.layoutMarginsGuide.topAnchor].active = YES;
        [imageView.leftAnchor constraintEqualToAnchor:tableHeaderContentView.layoutMarginsGuide.leftAnchor].active = YES;
        [imageView.bottomAnchor constraintEqualToAnchor:tableHeaderContentView.layoutMarginsGuide.bottomAnchor].active = YES;
        
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = .7f;
        [tableHeaderContentView addSubview:label];
        [label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [label.topAnchor constraintEqualToAnchor:tableHeaderContentView.layoutMarginsGuide.topAnchor].active = YES;
        [label.leftAnchor constraintEqualToAnchor:imageView.layoutMarginsGuide.rightAnchor].active = YES;
        [label.bottomAnchor constraintEqualToAnchor:tableHeaderContentView.layoutMarginsGuide.bottomAnchor].active = YES;
        [label.rightAnchor constraintEqualToAnchor:tableHeaderContentView.layoutMarginsGuide.rightAnchor].active = YES;
        _screenshotsCountLabel = label;
        
        CGRect rect = view.frame;
        rect.size.height = view.layoutMargins.top + view.layoutMargins.bottom + tableHeaderContentView.layoutMargins.top + tableHeaderContentView.layoutMargins.bottom + imageView.image.size.height;
        view.frame = rect;
        view;
    });
    
    _tableFooterTextView = ({
        UITextView *textView = [[UITextView alloc] init];
        textView.backgroundColor = [UIColor clearColor];
        textView.editable = NO;
        textView.scrollsToTop = NO;
        textView.scrollEnabled = NO;
        textView.dataDetectorTypes = UIDataDetectorTypeLink;
        textView.textAlignment = NSTextAlignmentCenter;
        textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        textView.adjustsFontForContentSizeCategory = YES;
        textView.text = @"Questions? Get in touch: info@screenshopit.com";
        textView.linkTextAttributes = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                        NSUnderlineColorAttributeName: [UIColor gray7]
                                        };
        textView;
    });
    
    self.tableFooterTextView.frame = [self rectForTableFooterTextView];
    
    _tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.translatesAutoresizingMaskIntoConstraints = NO;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundView = nil;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.tableHeaderView = tableHeaderView;
        tableView.tableFooterView = self.tableFooterTextView;
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        [self.view addSubview:tableView];
        [tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        [tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
        [tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        tableView;
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UIEdgeInsets insets = self.tableViewFollowSectionFooter.layoutMargins;
    insets.left = [self.tableView headerViewForSection:SectionTypeFollow].layoutMargins.left;
    self.tableViewFollowSectionFooter.layoutMargins = insets;
    
    
    CGRect tableFooterTextViewRect = [self rectForTableFooterTextView];
    
    if (self.tableView.tableFooterView.bounds.size.height != tableFooterTextViewRect.size.height) {
        self.tableFooterTextView.frame = tableFooterTextViewRect;
        self.tableView.tableFooterView = self.tableFooterTextView;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // TODO: why is the page scrolling after poping another vc (after commenting the below code)
    CGFloat offsetY = -self.tableView.contentInset.top;

    if (@available(iOS 11.0, *)) {
        offsetY = -self.tableView.adjustedContentInset.top;
    }

    self.tableView.contentOffset = CGPointMake(0.f, offsetY);
    
    [self updateScreenshotsCount];
    [self reloadPermissionIndexPaths];
    [self reloadDailyStreak];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self dismissKeyboard];
}

- (void)viewController:(UIViewController *)viewController willDisappear:(BOOL)animated {
    if ([viewController isKindOfClass:[CurrencyViewController class]]) {
        NSIndexPath *indexPath = [self indexPathForRowType:RowTypeCurrency inSectionType:SectionTypeInfo];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.view.window) {
        // Use did become active since this value can change through an alert view
        [self reloadPermissionIndexPaths];
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    if (self.view.window) {
        [self updateScreenshotsCount];
        [self reloadDailyStreak];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}


#pragma mark - Data

- (NSDictionary<NSNumber *, NSArray *> *)data {
    if (!_data) {
        _data = @{@(SectionTypePermissions): @[@(RowTypePhotoPermission),
                                               @(RowTypePushPermission),
//                                               @(RowTypeLocationService)
                                               ],
                  @(SectionTypeInfo): @[@(RowTypeName),
                                        @(RowTypeEmail),
                                        @(RowTypeCurrency)
                                        ],
                  @(SectionTypeAbout): @[
                                         @(RowTypeTellFriend),
                                         @(RowTypeTutorialVideo),
                                         @(RowTypeContactUs),
                                         @(RowTypeBug),
                                         @(RowTypeUsageStreak),
                                         @(RowTypeCoins),
                                         @(RowTypeVersion)
                                         ],
                  @(SectionTypeFollow): @[],
                  @(SectionTypeProducts): @[@(RowTypeProductGender),
//                                            @(RowTypeProductSize)
                                            ]
                  };
    }
    return _data;
}

- (RowType)rowTypeForIndexPath:(NSIndexPath *)indexPath {
    return self.data[@(indexPath.section)][indexPath.row].integerValue;
}

- (NSIndexPath *)indexPathForRowType:(RowType)rowType inSectionType:(SectionType)sectionType {
    NSInteger row = [self.data[@(sectionType)] indexOfObject:@(rowType)];
    return [NSIndexPath indexPathForRow:row inSection:sectionType];
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data[@(section)].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self textForSectionType:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == SectionTypeFollow) {
        return self.tableViewFollowSectionFooter;
        
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == SectionTypeFollow) {
        // FIXME: tableview first section title animation
        // this section is causing the first sections title to animate down
        // scroll to bottom, tap on another tab, tap back to settings
        return self.tableViewFollowSectionFooter.bounds.size.height;
        
    } else {
        return tableView.sectionFooterHeight;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RowType rowType = [self rowTypeForIndexPath:indexPath];
    UITableViewCell *cell;
    
    if (indexPath.section == SectionTypeInfo && (rowType == RowTypeName || rowType == RowTypeEmail)) {
        cell = [self tableView:tableView inputCellAtIndexPath:indexPath rowType:rowType];
        
    } else {
        cell = [self tableView:tableView defaultCellAtIndexPath:indexPath rowType:rowType];
    }
    
    cell.accessoryType = [self accessoryTypeForRowType:rowType];
    cell.accessoryView = [self accessoryViewForRowType:rowType];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView inputCellAtIndexPath:(NSIndexPath *)indexPath rowType:(RowType)rowType {
    UITextField *textField;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"input"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"input"];
        
        textField = [[UITextField alloc] init];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        textField.delegate = self;
        textField.tag = 1;
        textField.returnKeyType = UIReturnKeyDone;
        textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        textField.adjustsFontForContentSizeCategory = YES;
        [cell.contentView addSubview:textField];
        [textField.leadingAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.leadingAnchor].active = YES;
        [textField.trailingAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
        [textField.centerYAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.centerYAnchor].active = YES;
        
    } else {
        textField = [cell.contentView viewWithTag:1];
    }
    
    if (rowType == RowTypeEmail) {
        self.emailTextField = textField;
        textField.keyboardType = UIKeyboardTypeEmailAddress;
        
    } else if (rowType == RowTypeName) {
        self.nameTextField = textField;
        textField.keyboardType = UIKeyboardTypeDefault;
    }
    
    textField.text = [self textForRowType:rowType];
    textField.placeholder = [self detailTextForRowType:rowType];
    
    cell.textLabel.text = @" "; // Needed for adjusting the cell height correctly with dynamic type
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView defaultCellAtIndexPath:(NSIndexPath *)indexPath rowType:(RowType)rowType {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.text = [self textForRowType:rowType];
    cell.detailTextLabel.text = [self detailTextForRowType:rowType];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    RowType rowType = [self rowTypeForIndexPath:indexPath];
    
    switch (rowType) {
        case RowTypeVersion:
        case RowTypeEmail:
        case RowTypeCoins:
        case RowTypeProductGender:
        case RowTypeProductSize:
            return NO;
            break;
        case RowTypeLocationPermission:
        case RowTypePushPermission:
        case RowTypePhotoPermission:
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
            InviteViewController *viewController = [[InviteViewController alloc] init];
            viewController.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:viewController animated:YES];
        }
            break;
        case RowTypeTutorialVideo: {
            TutorialVideoViewController *viewController = [TutorialVideoViewControllerFactory replayViewController];
            viewController.showsReplayButtonUponFinishing = NO;
            viewController.delegate = self;
            viewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentViewController:viewController animated:YES completion:nil];
        }
            break;
        case RowTypeContactUs:
            [IntercomHelper.sharedInstance presentMessagingUI];
            break;
        case RowTypeLocationPermission:
        case RowTypePushPermission:
        case RowTypePhotoPermission: {
            [[PermissionsManager sharedPermissionsManager] requestPermissionForType:[self permissionTypeForRowType:rowType] openSettingsIfNeeded:YES response:^(BOOL granted) {
                if (granted) {
                    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    [self.delegate settingsViewControllerDidGrantPermission:self];
                }
            }];
        }
            break;
        case RowTypeCurrency: {
            CurrencyViewController *viewController = [[CurrencyViewController alloc] init];
            viewController.lifeCycleDelegate = self;
            viewController.title = [self textForRowType:rowType];
            viewController.hidesBottomBarWhenPushed = YES;
            viewController.selectedCurrencyCode = [[NSUserDefaults standardUserDefaults] stringForKey:[UserDefaultsKeys productCurrency]];
            [self.navigationController pushViewController:viewController animated:YES];
        }
            break;
        default:
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
        case SectionTypeInfo:
            return @"Your Info";
            break;
        case SectionTypeFollow:
            return @"Follow Us";
            break;
        case SectionTypeProducts:
            return @"Product Options";
            break;
    }
}

- (NSString *)textForRowType:(RowType)rowType {
    switch (rowType) {
        case RowTypeUsageStreak:
            return @"Daily Streak";
            break;
        case RowTypeBug:
            return @"Submit a Bug";
            break;
        case RowTypeTellFriend:
            return @"Tell a Friend";
            break;
        case RowTypeContactUs:
            return @"Contact Us";
            break;
        case RowTypeTutorialVideo:
            return @"Replay Tutorial";
            break;
        case RowTypeName:
            return [[NSUserDefaults standardUserDefaults] stringForKey:UserDefaultsKeys.name];
            break;
        case RowTypeEmail:
            return [[NSUserDefaults standardUserDefaults] stringForKey:UserDefaultsKeys.email];
            break;
        case RowTypeLocationPermission:
            return @"Location Services";
            break;
        case RowTypePushPermission:
            return @"Push Notifications";
            break;
        case RowTypePhotoPermission:
            return @"Camera Roll";
            break;
        case RowTypeVersion:
            return @"App Version";
            break;
        case RowTypeCoins:
            return @"Coins Collected";
            break;
        case RowTypeProductGender:
            return @"Gender";
            break;
        case RowTypeProductSize:
            return @"Size";
            break;
        case RowTypeCurrency:
            return @"Currency";
            break;
    }
}

- (NSString *)detailTextForRowType:(RowType)rowType {
    switch (rowType) {
        case RowTypePhotoPermission:
        case RowTypeLocationPermission:
        case RowTypePushPermission:
            return [self enabledTextForRowType:rowType];
            break;
        case RowTypeUsageStreak: {
            NSInteger streak = [NSUserDefaults.standardUserDefaults integerForKey:[UserDefaultsKeys dailyStreak]];
            NSString *suffix = (streak == 0 || streak > 1) ? @"s" : @"";
            return [NSString stringWithFormat:@"%ld day%@", streak, suffix];
            break;
        }
        case RowTypeVersion:
            return [NSString stringWithFormat:@"%@%@", [NSBundle displayVersionBuild], [Constants buildEnvironmentSuffix]];
            break;
        case RowTypeName:
            return @"Enter Your Name";
            break;
        case RowTypeEmail:
            return @"Enter Your Email";
            break;
        case RowTypeCoins:
            return [NSString stringWithFormat:@"%ld", (long)[[NSUserDefaults standardUserDefaults] integerForKey:[UserDefaultsKeys gameScore]]];
            break;
        case RowTypeCurrency:
            return [[NSUserDefaults standardUserDefaults] stringForKey:[UserDefaultsKeys productCurrency]];
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
        case RowTypeTellFriend:
        case RowTypeCurrency:
            return UITableViewCellAccessoryDisclosureIndicator;
            break;
        default:
            return UITableViewCellAccessoryNone;
            break;
    }
}

- (UIView *)accessoryViewForRowType:(RowType)rowType {
    switch (rowType) {
        case RowTypePhotoPermission:
        case RowTypePushPermission: {
            UILabel *label;
            
            if (![[PermissionsManager sharedPermissionsManager] hasPermissionForType:[self permissionTypeForRowType:rowType]]) {
                CGFloat size = 18.f;
                
                label = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, size, size)];
                label.backgroundColor = [UIColor crazeRed];
                label.text = @"!";
                label.textAlignment = NSTextAlignmentCenter;
                label.font = [UIFont fontWithName:@"Optima-ExtraBlack" size:14.f];
                label.textColor = [UIColor whiteColor];
                label.layer.cornerRadius = size / 2.f;
                label.layer.masksToBounds = YES;
            }
            
            return label;
        }
            break;
        case RowTypeProductGender: {
            // TODO: use ProductsOptions after swift converstion
            
            UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:@[@"Female", @"Male", @"All"]];
            control.tintColor = [UIColor crazeGreen];
            control.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:[UserDefaultsKeys productGender]];
            [control addTarget:self action:@selector(genderControlAction:) forControlEvents:UIControlEventValueChanged];
            return control;
        }
            break;
        default:
            return nil;
            break;
    }
}

- (void)reloadDailyStreak {
    [UsageStreakHelper updateStreak];
    
    NSIndexPath *indexPath = [self indexPathForRowType:RowTypeUsageStreak inSectionType:SectionTypeAbout];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)reloadPermissionIndexPaths {
    NSMutableArray *permissionIndexPaths = [NSMutableArray array];
    NSInteger section = SectionTypePermissions;
    
    for (NSNumber *permissionNumber in [self data][@(section)]) {
        [permissionIndexPaths addObject:[NSIndexPath indexPathForRow:[permissionNumber integerValue] inSection:section]];
    }
    
    [self.tableView reloadRowsAtIndexPaths:permissionIndexPaths withRowAnimation:UITableViewRowAnimationFade];
}

- (CGRect)rectForTableFooterTextView {
    CGFloat maxWidth = self.view.bounds.size.width - self.tableFooterTextView.textContainerInset.left - self.tableFooterTextView.textContainerInset.right;
    CGSize size = CGSizeMake(maxWidth, CGFLOAT_MAX);
    
    CGRect rect = [self.tableFooterTextView.attributedText boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:NULL];
    rect.size.width = ceil(rect.size.width) + self.tableFooterTextView.textContainerInset.left + self.tableFooterTextView.textContainerInset.right;
    rect.size.height = ceil(rect.size.height) + self.tableFooterTextView.textContainerInset.top + self.tableFooterTextView.textContainerInset.bottom + [Geometry padding];
    return rect;
}


#pragma mark - Text Field

- (NSMutableDictionary<NSString *,NSString *> *)previousTexts {
    if (!_previousTexts) {
        _previousTexts = [NSMutableDictionary dictionary];
        _previousTexts[UserDefaultsKeys.name] = [self textForRowType:RowTypeName];
        _previousTexts[UserDefaultsKeys.email] = [self textForRowType:RowTypeEmail];
    }
    return _previousTexts;
}

- (NSString *)keyForTextField:(UITextField *)textField {
    if (textField == self.emailTextField) {
        return UserDefaultsKeys.email;
        
    } else if (textField == self.nameTextField) {
        return UserDefaultsKeys.name;
    }
    
    return nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyDone) {
        [textField resignFirstResponder];
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSString *key = [self keyForTextField:textField];
    NSString *trimmedText = [textField.text trimWhitespace];
    BOOL canContinue = NO;
    
    if ([key isEqualToString:UserDefaultsKeys.email]) {
        canContinue = [textField.text isValidEmail];
        
    } else if ([key isEqualToString:UserDefaultsKeys.name]) {
        canContinue = trimmedText.length > 0;
    }
    
    if (canContinue) {
        self.previousTexts[key] = trimmedText;
        textField.text = trimmedText;
        
        [[NSUserDefaults standardUserDefaults] setValue:trimmedText forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self reidentify];
        
    } else {
        textField.text = self.previousTexts[key];
    }
}

- (void)reidentify {
    AnalyticsUser *user = [[AnalyticsUser alloc] initWithName:[self.nameTextField.text trimWhitespace] email:[self.emailTextField.text trimWhitespace]];
    
    [AnalyticsTrackers.standard identify:user];
    [AnalyticsTrackers.branch identify:user];
}

- (void)dismissKeyboard {
    [self.tableView endEditing:YES];
}


#pragma mark - Screenshots Count

- (NSString *)screenshotsCountText {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSUInteger screenshotCount = [[DataModel sharedInstance] countTotalScreenshots];
    NSString *numberString = [formatter stringFromNumber:@(screenshotCount)];
    NSString *sString = (screenshotCount == 1) ? @"" : @"s";
    return [NSString stringWithFormat:@"%@ screenshot%@", numberString, sString];
}

- (void)layoutScreenshotsCountShadow {
    [self.tableHeaderContentView layoutIfNeeded];
    self.tableHeaderContentView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.tableHeaderContentView.bounds cornerRadius:self.tableHeaderContentView.layer.cornerRadius].CGPath;
}

- (void)updateScreenshotsCount {
    self.screenshotsCountLabel.text = [self screenshotsCountText];
    [self layoutScreenshotsCountShadow];
}


#pragma mark - Follow Buttons

- (UIView *)tableViewFollowSectionFooter {
    if (!_tableViewFollowSectionFooter) {
        UIButton * (^createButton)(NSString *, SEL) = ^UIButton * (NSString *imageName, SEL action){
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.imageView.contentMode = UIViewContentModeScaleAspectFit;
            [button setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
            [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
            button.adjustsImageWhenHighlighted = NO;
            [button sizeToFit];
            return button;
        };
        
        UIButton *facebookButton = createButton(@"SettingsFacebook", @selector(facebookButtonAction));
        UIButton *instagramButton = createButton(@"SettingsInstagram", @selector(instagramButtonAction));
        
        CGFloat tableSectionHeaderLabelOffsetY = 15.5f;
        CGRect rect = CGRectZero;
        rect.size.height = facebookButton.bounds.size.height + self.tableView.sectionFooterHeight + tableSectionHeaderLabelOffsetY;
        UIView *view = [[UIView alloc] initWithFrame:rect];
        
        [view addSubview:instagramButton];
        [instagramButton.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
        [instagramButton.leadingAnchor constraintEqualToAnchor:view.layoutMarginsGuide.leadingAnchor].active = YES;
        
        [view addSubview:facebookButton];
        [facebookButton.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
        [facebookButton.leadingAnchor constraintEqualToAnchor:instagramButton.trailingAnchor constant:20.0f].active = YES;
        
        [view layoutIfNeeded];
        _tableViewFollowSectionFooter = view;
    }
    return _tableViewFollowSectionFooter;
}

- (void)facebookButtonAction {
    NSURL *url = [NSURL URLWithString:@"https://www.facebook.com/screenshopit/"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)instagramButtonAction {
    NSURL *url = [NSURL URLWithString:@"https://www.instagram.com/screenshopit/"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}


#pragma mark - Product Options

- (void)genderControlAction:(UISegmentedControl *)control {
    [[NSUserDefaults standardUserDefaults] setInteger:control.selectedSegmentIndex forKey:[UserDefaultsKeys productGender]];
}


#pragma mark - Permissions

- (PermissionType)permissionTypeForRowType:(RowType)rowType {
    switch (rowType) {
        case RowTypePhotoPermission:
            return PermissionTypePhoto;
            break;
        case RowTypeLocationPermission:
            return PermissionTypeLocation;
            break;
        case RowTypePushPermission:
        default:
            return PermissionTypePush;
            break;
    }
}


#pragma mark - Tutorial

- (void)tutoriaViewControllerDidComplete:(TutorialViewController *)viewController {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Mail

- (void)presentMailComposer {
    if ([MFMailComposeViewController canSendMail]) {
        NSArray *message = @[@"\n\n\n",
                             @"-----------------",
                             @"Don't edit below.\n",
                             [NSString stringWithFormat:@"version: %@", [NSBundle displayVersionBuild]]
                             ];
        
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        mail.mailComposeDelegate = self;
        [mail setSubject:@"Bug Report"];
        [mail setMessageBody:[message componentsJoinedByString:@"\n"] isHTML:NO];
        [mail setToRecipients:@[@"support@screenshopit.com"]];
        
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


#pragma mark - TutorialVideoViewControllerDelegate

- (void)tutorialVideoViewControllerDoneButtonTapped:(TutorialVideoViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tutorialVideoViewControllerDidEnd:(TutorialVideoViewController *)viewController {
    [AnalyticsTrackers.standard track:@"Automatically Exited Tutorial Video" properties:nil];
    
    // TODO: look into why this is here - corey
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

@end

