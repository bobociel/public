//
//  FileModel.h
//  AliOSS
//
//  Created by wangxiaobo on 12/18/15.
//  Copyright © 2015 wangxiaobo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileModel : NSObject
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *ETag;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *LastModefied;
@property (nonatomic, assign)double Size;
@property (nonatomic, assign)NSInteger type;

@end
