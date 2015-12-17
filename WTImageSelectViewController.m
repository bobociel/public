//
//  WTImageSelectViewController.m
//  weddingTime
//
//  Created by wangxiaobo on 15/12/11.
//  Copyright © 2015年 lovewith.me. All rights reserved.
//
#import "WTImageSelectViewController.h"
#import "WTImageCell.h"
#import "AppDelegate.h"
#define kNavBarHeight 64.0
#define kButtonHeight 50.0
#define kCellWidth ((screenWidth - 15) / 4.0)
#define kCellHeight ((screenWidth - 15) / 4.0)
@interface WTImageSelectViewController ()
<
	UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,
	WTImageCellDelegate
>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic, strong) UIButton *sureButton;
@property (nonatomic, strong) NSMutableArray *localAssets;
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionBottom;
@end

@implementation WTImageSelectViewController

+ (ALAssetsLibrary *)assetLibrary
{
	static ALAssetsLibrary *assetLibrary;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		assetLibrary = [[ALAssetsLibrary alloc] init];
	});
	return assetLibrary;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title =  self.fileType == WTFileTypeImage ? @"所有相片" : @"所有视频";

	self.localAssets = [NSMutableArray array];
	self.selectedAssets = [NSMutableArray array];
	[self loadAsset];

	self.collectionView.delegate = self;
	self.collectionView.dataSource = self;
	[self.collectionView registerNib:[UINib nibWithNibName:@"WTImageCell" bundle:nil] forCellWithReuseIdentifier:@"WTImageCell"];

	self.sureButton = [UIButton buttonWithType:UIButtonTypeSystem];
	self.sureButton.frame = CGRectMake(0, screenHeight-kNavBarHeight , screenWidth,kButtonHeight);
	[self.sureButton setBackgroundColor:WeddingTimeBaseColor];
	[self.sureButton setTitle:@"确定" forState:UIControlStateNormal];
	[self.sureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[self.view addSubview:self.sureButton];
	[self.sureButton addTarget:self action:@selector(choosedImage:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)loadAsset
{
	[self.activityView startAnimating];
	[[WTImageSelectViewController assetLibrary] enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
		if(group){
			ALAssetsFilter *filter = self.fileType == WTFileTypeImage ? [ALAssetsFilter allPhotos] : [ALAssetsFilter allVideos];
			[group setAssetsFilter:filter];
			[group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
				if(result){
					[self.localAssets addObject:result];
				}else{
					[self.collectionView reloadData];
					[self.activityView stopAnimating];
					self.activityView.hidden = YES;
				}
			}];
		}
		else
		{
			[self.activityView stopAnimating];
			self.activityView.hidden = YES;
		}
	} failureBlock:^(NSError *error) {
		[self.activityView stopAnimating];
		self.activityView.hidden = YES;
	}];
}

- (void)choosedImage:(UIButton *)btn
{
	self.block(WTFileTypeImage,self.selectedAssets,nil);
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Collection View
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.localAssets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	WTImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WTImageCell" forIndexPath:indexPath];
	cell.delegate = self;
	cell.asset = self.localAssets[indexPath.row];
	return cell;
}

- (void)WTImageCell:(WTImageCell *)cell didClickWithAsset:(ALAsset *)asset
{
	if(self.fileType == WTFileTypeImage)
    {
		if(asset )
        {
			![self.selectedAssets containsObject:asset] ? [self.selectedAssets addObject:asset] : [self.selectedAssets removeObject:asset] ;
		}
		CGFloat y = self.selectedAssets.count > 0 ? screenHeight - kNavBarHeight - kButtonHeight : screenHeight - kNavBarHeight ;
		[UIView animateWithDuration:0.25 animations:^{
			self.sureButton.frame = CGRectMake(0, y , screenWidth, kButtonHeight);
			self.collectionBottom.constant = self.selectedAssets.count > 0 ?   kButtonHeight :  0;
			[self.view layoutIfNeeded];
		} completion:^(BOOL finished) {
			
		}];
	}
	else
	{
		self.block(WTFileTypeVideo,nil,asset);
        [self.navigationController popViewControllerAnimated:YES];
	}
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return CGSizeMake(kCellWidth, kCellHeight);
}


@end
