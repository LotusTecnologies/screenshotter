//
//  SettingsViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "SettingsViewController.h"
#import "Geometry.h"
#import "PermissionsManager.h"

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
    RowTypeBug,
    RowTypeVersion
};

@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *data;

@end

@implementation SettingsViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Settings";
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
        
        UIView *centerView = [[UIView alloc] init];
        centerView.translatesAutoresizingMaskIntoConstraints = NO;
        [view addSubview:centerView];
        [centerView.topAnchor constraintEqualToAnchor:view.layoutMarginsGuide.topAnchor].active = YES;
        [centerView.bottomAnchor constraintEqualToAnchor:view.layoutMarginsGuide.bottomAnchor].active = YES;
        [centerView.centerXAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
        [centerView.leftAnchor constraintGreaterThanOrEqualToAnchor:view.layoutMarginsGuide.leftAnchor].active = YES;
        [centerView.rightAnchor constraintLessThanOrEqualToAnchor:view.layoutMarginsGuide.rightAnchor].active = YES;
        
        UIImageView *badgeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Badge"]];
        badgeImageView.translatesAutoresizingMaskIntoConstraints = NO;
        badgeImageView.contentMode = UIViewContentModeScaleAspectFit;
        badgeImageView.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, 0.f, -p);
        [centerView addSubview:badgeImageView];
        [badgeImageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [badgeImageView.topAnchor constraintEqualToAnchor:centerView.topAnchor].active = YES;
        [badgeImageView.leftAnchor constraintEqualToAnchor:centerView.leftAnchor].active = YES;
        [badgeImageView.bottomAnchor constraintEqualToAnchor:centerView.bottomAnchor].active = YES;
        
        UIImageView *barImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Bar"]];
        barImageView.translatesAutoresizingMaskIntoConstraints = NO;
        barImageView.contentMode = UIViewContentModeScaleAspectFit;
        barImageView.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, -4.f, 0.f);
        [centerView addSubview:barImageView];
        [barImageView.layoutMarginsGuide.bottomAnchor constraintEqualToAnchor:centerView.centerYAnchor].active = YES;
        [barImageView.leftAnchor constraintEqualToAnchor:badgeImageView.layoutMarginsGuide.rightAnchor].active = YES;
        [barImageView.rightAnchor constraintEqualToAnchor:centerView.rightAnchor].active = YES;
        
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.layoutMargins = UIEdgeInsetsMake(-4.f, 0.f, 0.f, 0.f);
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"3 screenshots to next level";
        [centerView addSubview:label];
        [label.layoutMarginsGuide.topAnchor constraintEqualToAnchor:centerView.centerYAnchor].active = YES;
        [label.leftAnchor constraintEqualToAnchor:barImageView.leftAnchor].active = YES;
        [label.rightAnchor constraintEqualToAnchor:barImageView.rightAnchor].active = YES;
        
        CGRect rect = view.frame;
        rect.size.height = badgeImageView.bounds.size.height + view.layoutMargins.top + view.layoutMargins.bottom;
        view.frame = rect;
        view;
    });
    
    UITextView *tableFooterTextView = ({
        UITextView *textView = [[UITextView alloc] init];
        textView.backgroundColor = [UIColor clearColor];
        textView.editable = NO;
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
}


#pragma mark - Data

- (NSDictionary *)dataDict {
    return @{@(SectionTypePermissions): @[@(RowTypeCameraRoll),
                                          @(RowTypePushNotification),
                                          @(RowTypeLocationService)
                                          ],
             @(SectionTypeEmail): @[@(RowTypeEmail)
                                    ],
             @(SectionTypeAbout): @[@(RowTypeTutorial),
                                    @(RowTypeTellFriend),
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
            // TODO: open email modal to support@crazeapp.com
            break;
        case RowTypeTellFriend:
            // TODO: open share sheet to crazeapp.com/app
            break;
        case RowTypeTutorial:
            // TODO: open onboarding tutorial
            break;
        case RowTypeEmail:
            break;
        case RowTypeLocationService:
        case RowTypePushNotification:
        case RowTypeCameraRoll: {
            [[PermissionsManager sharedPermissionsManager] requestPermissionForType:[self permissionTypeForRowType:rowType] response:^(BOOL granted) {
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
        case RowTypeTutorial:
            return @"Replay Tutorial";
            break;
        case RowTypeEmail:
            return @"*email value*";
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
            return @"*version number*";
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
        case RowTypeTellFriend:
        case RowTypeBug:
            return UITableViewCellAccessoryDisclosureIndicator;
            break;
        default:
            return UITableViewCellAccessoryNone;
            break;
    }
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

@end
