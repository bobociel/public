//
//  ViewController.h
//  AliOSS
//
//  Created by wangxiaobo on 12/16/15.
//  Copyright © 2015 wangxiaobo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *fileName;
@end

@interface ViewController : UIViewController

+ (instancetype)instance;
@end

