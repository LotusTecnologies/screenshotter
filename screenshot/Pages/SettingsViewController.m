//
//  SettingsViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "SettingsViewController.h"

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
    
    self.tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.translatesAutoresizingMaskIntoConstraints = NO;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundView = nil;
        tableView.backgroundColor = [UIColor clearColor];
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
    return [self rowTypeForIndexPath:indexPath] != RowTypeVersion;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self rowTypeForIndexPath:indexPath]) {
        case RowTypeBug:
            
            break;
        case RowTypeTellFriend:
            
            break;
        case RowTypeTutorial:
            
            break;
        case RowTypeEmail:
            
            break;
        case RowTypeLocationService:
            
            break;
        case RowTypePushNotification:
            
            break;
        case RowTypeCameraRoll:
            
            break;
        case RowTypeVersion:
            break;
    }
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
    NSString *(^enabledText)(BOOL) = ^(BOOL isEnabled) {
        return isEnabled ? @"Enabled" : @"Disabled";
    };
    
    switch (rowType) {
        case RowTypeCameraRoll:
            return enabledText(YES);
            break;
        case RowTypeLocationService:
            return enabledText(YES);
            break;
        case RowTypePushNotification:
            return enabledText(NO);
            break;
        case RowTypeVersion:
            return @"*version number*";
            break;
        default:
            return nil;
            break;
    }
}

- (UITableViewCellAccessoryType)accessoryTypeForRowType:(RowType)rowType {
    switch (rowType) {
        case RowTypeEmail:
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

@end
