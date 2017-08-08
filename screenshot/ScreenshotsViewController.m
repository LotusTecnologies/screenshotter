//
//  ScreenshotsViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotsViewController.h"
#import "ScreenshotCollectionViewCell.h"

@interface ScreenshotsViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation ScreenshotsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor yellowColor];
    
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = [self padding];
    layout.minimumLineSpacing = [self padding];
    
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    
    [self.collectionView registerClass:[ScreenshotCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [self.collectionView setBackgroundColor:[UIColor redColor]];
    
    [self.view addSubview:self.collectionView];
    [self.collectionView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
    [self.collectionView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor].active = YES;
    [self.collectionView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:[self padding]].active = YES;
    [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-[self padding]].active = YES;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (CGFloat)padding {
    return 16;
}

- (NSInteger)numberOfCollectionViewColumns {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 15;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ScreenshotCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor greenColor];
    cell.imageView = nil; // TODO: set this
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger columns = [self numberOfCollectionViewColumns];
    
    CGSize size = CGSizeZero;
    size.width = (collectionView.bounds.size.width - ((columns - 1) * [self padding])) / columns;
    size.height = size.width;
    return size;
}

@end
