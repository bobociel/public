//
//  OSSManager.m
//  AliOSS
//
//  Created by wangxiaobo on 12/17/15.
//  Copyright © 2015 wangxiaobo. All rights reserved.
//

#import "OSSManager.h"

NSString * const AccessKey = @"yoJo65HzedUz6VWL";
NSString * const SecretKey = @"0A3Pc7TkqBz0VHU7byqBk6hLnpP6r8";
NSString * const endPoint  = @"http://oss-cn-hangzhou.aliyuncs.com";
@interface OSSManager()
@property (nonatomic, strong) OSSClient *client;
@property (nonatomic, strong) OSSGetBucketRequest    *bucketGetReq;
@property (nonatomic, strong) OSSCreateBucketRequest *bucketCreReq;
@property (nonatomic, strong) OSSDeleteBucketRequest *bucketDelReq;

@property (nonatomic, strong) OSSGetObjectRequest    *objectGetReq;
@property (nonatomic, strong) OSSPutObjectRequest    *objectPutReq;
@property (nonatomic, strong) OSSAppendObjectRequest *objectAddReq;
@property (nonatomic, strong) OSSDeleteObjectRequest *objectDelReq;
@end

@implementation OSSManager

+ (instancetype)manager
{
    static OSSManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[OSSManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        id<OSSCredentialProvider> credential = [[OSSPlainTextAKSKPairCredentialProvider alloc] initWithPlainTextAccessKey:AccessKey secretKey:SecretKey];

        OSSClientConfiguration * conf = [OSSClientConfiguration new];
        conf.maxRetryCount = 2;
        conf.timeoutIntervalForRequest = 30;
        conf.timeoutIntervalForResource = 24 * 60 * 60;

        self.client = [[OSSClient alloc] initWithEndpoint:endPoint credentialProvider:credential clientConfiguration:conf];

        self.bucketGetReq = [OSSGetBucketRequest new];
		self.bucketCreReq = [OSSCreateBucketRequest new];
		self.bucketDelReq = [OSSDeleteBucketRequest new];
        self.bucketGetReq.bucketName = @"bucketcell";
		self.bucketCreReq.bucketName = @"bucketcell";
		self.bucketDelReq.bucketName = @"bucketcell";

        self.objectGetReq = [OSSGetObjectRequest new];
		self.objectPutReq = [OSSPutObjectRequest new];
		self.objectAddReq = [OSSAppendObjectRequest new];
		self.objectDelReq = [OSSDeleteObjectRequest new];
        self.objectGetReq.bucketName = @"bucketcell";
		self.objectPutReq.bucketName = @"bucketcell";
		self.objectAddReq.bucketName = @"bucketcell";
		self.objectDelReq.bucketName = @"bucketcell";
    }
    return self;
}

- (NSString *)filePath
{
	NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingString:@"/OSSDownload"];
	return filePath;
}

- (NSString *)filePathWithKey:(NSString *)key
{
	NSString *filePath = [NSString stringWithFormat:@"%@/%@",[self filePath],[key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	return filePath;
}

#pragma mark - Bucket
- (void)getBucketListWithPrefix:(NSString *)prefix andDelimiter:(NSString *)del success:(void(^)(NSArray *result))success failure:(void(^)(NSError *error))failure
{
    self.bucketGetReq.delimiter = @"/";
    self.bucketGetReq.prefix = prefix;

    OSSTask * getBucketTask = [self.client getBucket:self.bucketGetReq];
    [getBucketTask continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            OSSGetBucketResult * result = task.result;
            NSMutableArray *fileArray = [NSMutableArray array];
            [result.commentPrefixes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
                FileModel *file = [[FileModel alloc] init];
                file.fileName = obj;
                [fileArray addObject:file];
            }];

            [result.contents enumerateObjectsUsingBlock:^(id  obj, NSUInteger idx, BOOL * stop) {
                FileModel *fileModel = [[FileModel alloc] init];
                fileModel.ETag = obj[@"ETag"];
                fileModel.key = obj[@"Key"];
                [fileArray addObject:fileModel];
            }];

            success(fileArray);
        } else {
            failure(task.error);
        }
        return nil;
    }];
}

- (void)createBucketWithKey:(NSString *)key success:(void(^)(NSArray *result))success failure:(void(^)(NSError *error))failure
{

}

#pragma mark - object
- (void)getObjectWithKey:(NSString *)key success:(void(^)(NSString *filePath))success failure:(void(^)(NSError *))failure
{
    self.objectGetReq.objectKey = key;
    if([[NSFileManager defaultManager] fileExistsAtPath:[self filePathWithKey:key]])
    {
        success([self filePathWithKey:key]);
    }
    else
    {
        self.objectGetReq.downloadToFileURL = [NSURL URLWithString:[self filePathWithKey:key]];
        self.objectGetReq.downloadProgress = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
            NSLog(@"%lld, %lld, %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        };

        OSSTask * getTask = [self.client getObject:self.objectGetReq];

        [getTask continueWithBlock:^id(OSSTask *task) {
            if (!task.error) {
                success([[self filePathWithKey:key] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
            } else {
                failure(task.error);
            }
            return nil;
        }];
    }
}

- (void)putObjectWithKey:(NSString *)key andFileInfo:(id)fileInfo success:(void(^)(NSString *filePath))success failure:(void(^)(NSError *))failure
{

}



@end
