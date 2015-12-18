//
//  OSSManager.h
//  AliOSS
//
//  Created by wangxiaobo on 12/17/15.
//  Copyright © 2015 wangxiaobo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AliyunOSSiOS/OSSService.h>
#import "FileModel.h"
@interface OSSManager : NSObject

+ (instancetype)manager;

- (void)getBucketListWithPrefix:(NSString *)prefix
                   andDelimiter:(NSString *)del
                        success:(void(^)(NSArray *result))success
                        failure:(void(^)(NSError *error))failure;

- (void)getObjectWithKey:(NSString *)key
                 success:(void(^)(NSString *filePath))success
                 failure:(void(^)(NSError *))failure;
@end
