//
//  ViewController.m
//  AliOSS
//
//  Created by wangxiaobo on 12/16/15.
//  Copyright © 2015 wangxiaobo. All rights reserved.
//

#import "ViewController.h"
#import "OSSManager.h"

@implementation FileCell

@end

@interface ViewController ()
<
UICollectionViewDelegate,UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout,
UIDocumentInteractionControllerDelegate
>
@property (nonatomic, copy) NSString *preStr;
@property (nonatomic, strong) NSMutableArray *fileArray;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) UIDocumentInteractionController *documentVC;
@end

@implementation ViewController

+ (instancetype)instance
{
    ViewController *VC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ViewController"];
    return VC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.fileArray = [NSMutableArray array];

    [[OSSManager manager] getBucketListWithPrefix:self.preStr andDelimiter:@"" success:^(NSArray *result) {
        self.fileArray = [NSMutableArray arrayWithArray:result];
		dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
    } failure:^(NSError *error) {

    }];

}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.fileArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FileCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FileCell" forIndexPath:indexPath];
    FileModel *fileModel = self.fileArray[indexPath.row];
    cell.fileName.text = fileModel.fileName.length >0 ? fileModel.fileName:fileModel.key;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FileModel *fileModel = self.fileArray[indexPath.row];
    if(fileModel.fileName.length >0)
    {
        ViewController *VC = [ViewController instance];
        VC.preStr = fileModel.fileName;
        [self.navigationController pushViewController:VC animated:YES];
    }
    else
    {
        [[OSSManager manager] getBucketWithKey:fileModel.key success:^(NSString *filePath) {
            self.documentVC = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:filePath]];
            self.documentVC.delegate = self;
//            [self.documentVC presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
            [self.documentVC presentPreviewAnimated:YES];
        } failure:^(NSError *error) {

        }];

    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return CGSizeMake( ([UIScreen mainScreen].bounds.size.width - 60.0) /3.0, ([UIScreen mainScreen].bounds.size.width - 60.0) /3.0);
}


#pragma mark - Document

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self;
}

- (UIView *)documentInteractionControllerViewForPreview:(UIDocumentInteractionController *)controller
{
    return self.view;
}

@end

