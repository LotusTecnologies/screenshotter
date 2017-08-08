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
    SectionPermissions,
    SectionEmail,
    SectionAbout
};

typedef NS_ENUM(NSUInteger, RowType) {
    RowCameraRoll,
    RowPushNotification,
    RowLocationService,
    RowEmail,
    RowTutorial,
    RowTellFriend,
    RowBug,
    RowVersion
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
    return @{@(SectionPermissions): @[@(RowCameraRoll),
                                      @(RowPushNotification),
                                      @(RowLocationService)
                                      ],
             @(SectionEmail): @[@(RowEmail)
                                ],
             @(SectionAbout): @[@(RowTutorial),
                                @(RowTellFriend),
                                @(RowBug),
                                @(RowVersion)
                                ]
             };
}

- (NSArray *)data {
    if (!_data) {
        NSDictionary *dict = [self dataDict];
        
        _data = @[[dict objectForKey:@(SectionPermissions)],
                  [dict objectForKey:@(SectionEmail)],
                  [dict objectForKey:@(SectionAbout)]];
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
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.text = [self textForRowType:[self rowTypeForIndexPath:indexPath]];
    cell.detailTextLabel.text = @"test";
    return cell;
}

- (NSString *)textForSectionType:(SectionType)sectionType {
    switch (sectionType) {
        case SectionPermissions:
            return @"Permissions";
            break;
        case SectionAbout:
            return @"About";
            break;
        case SectionEmail:
            return @"Email";
            break;
    }
}

- (NSString *)textForRowType:(RowType)rowType {
    switch (rowType) {
        case RowBug:
            return @"Submit a Bug";
            break;
        case RowTellFriend:
            return @"Tell a Friend";
            break;
        case RowTutorial:
            return @"Replay Tutorial";
            break;
        case RowEmail:
            return @"*email value*";
            break;
        case RowLocationService:
            return @"Location Services";
            break;
        case RowPushNotification:
            return @"Push Notifications";
            break;
        case RowCameraRoll:
            return @"Camera Roll";
            break;
        case RowVersion:
            return @"App Version";
            break;
    }
}

@end
