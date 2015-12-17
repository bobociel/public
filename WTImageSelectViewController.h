//
//  WTImageSelectViewController.h
//  weddingTime
//
//  Created by wangxiaobo on 15/12/11.
//  Copyright © 2015年 lovewith.me. All rights reserved.
//

typedef void(^SelectedBlock)(WTFileType fileType,NSArray *array,ALAsset *asset);
#import "BaseViewController.h"

@interface WTImageSelectViewController : BaseViewController
@property (nonatomic, assign) WTFileType fileType;
@property (nonatomic, copy) SelectedBlock block;
- (void)setBlock:(SelectedBlock)block;
@end
