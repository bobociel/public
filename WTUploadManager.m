//
//  TWUploadManager.m
//  weddingTime
//
//  Created by wangxiaobo on 15/12/7.
//  Copyright © 2015年 lovewith.me. All rights reserved.
//

#import "WTUploadManager.h"
#import "PostDataService.h"
#import "GetService.h"

#define kReachabilityURL @"https://www.baidu.com"
@interface  WTUploadManager()
@property (nonatomic, copy) NSString *pathAndKey;
@property (nonatomic, copy) NSString *fileKey;
@property (nonatomic, copy) NSString *filePath;
@end

@implementation WTUploadManager
+ (instancetype)manager
{
    static WTUploadManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[WTUploadManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if(self){
        self.fileRecord = [QNFileRecorder fileRecorderWithFolder:[self fileRecordPath] error:nil];
        if(self.fileRecord){
            self.uploadManager = [[QNUploadManager alloc] initWithRecorder:self.fileRecord recorderKeyGenerator:^NSString *(NSString *uploadKey, NSString *filePath) {
                return [[NSString stringWithFormat:@"%@&&%@",filePath,uploadKey] stringByReplacingOccurrencesOfString:@"/" withString:@"#"];
            }];
        }
        else{
            self.uploadManager = [[QNUploadManager alloc] init];
        }

        self.reachebility = [QNReachability reachabilityWithHostName:APIHOST] ;
        self.uploadState = WTUploadStatueNone;
        self.isCancelUpload = NO;
        [self.reachebility startNotifier];
        [self addObserver:self forKeyPath:@"uploadState" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if([self.delegate respondsToSelector:@selector(uploadManager:didChangeUploadState:)]){
        [self.delegate uploadManager:self didChangeUploadState:(WTUploadStatue)[change[NSKeyValueChangeNewKey] integerValue]];
    }
}

#pragma mark -  Local Cache
- (NSString *)fileRecordPath{
    NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSLog(@"cacheDir : %@",cacheDir);
    return [cacheDir stringByAppendingString:@"/QiNiuCache"];
}

- (BOOL)hasCache{
    NSMutableArray *files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self fileRecordPath] error:nil] mutableCopy];
    [files removeObject:@".DS_Store"];
    return files.count > 0;
}

- (void)resumeUploadCache{
    self.uploadState = WTUploadStatueUploading;
    NSMutableArray *files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self fileRecordPath] error:nil] mutableCopy];
    [files removeObject:@".DS_Store"];
    if(files.count>0){
        NSArray *atts = [[files[0] stringByReplacingOccurrencesOfString:@"#" withString:@"/"] componentsSeparatedByString:@"&&"];
        self.pathAndKey = files[0];
        self.filePath = atts[0];
        self.fileKey = atts[1];
        [self uploadFileWithBucket:@"mt-video" fileInfo:self.filePath fileType:WTFileTypeVideo];
    }
}

- (void)deleteCache{
    self.uploadState = WTUploadStatueCanceled;
    NSMutableArray *files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self fileRecordPath] error:nil] mutableCopy];
    [files removeObject:@".DS_Store"];
    if(files.count>0){
        NSError *error ;
        self.pathAndKey = files[0];
        BOOL isRemove = [[NSFileManager defaultManager] removeItemAtPath:[[self fileRecordPath] stringByAppendingPathComponent:self.pathAndKey] error:&error];
        if(isRemove){
            NSLog(@"Delete Cache OK");
        }
    }
}

#pragma mark - Upload
- (void)uploadFileWithBucket:(NSString *)bucket fileInfo:(id)filePathOrData fileType:(WTFileType)fileType
{
    self.isCancelUpload = NO;
    self.uploadState = WTUploadStatueUploading;
    NSString *fileMIME = fileType == WTFileTypeImage ? @"image/jpeg" : @"video/quicktime";
    //设置上传选项
    self.uploadOption = [[QNUploadOption alloc] initWithMime:fileMIME progressHandler:^(NSString *key, float percent) {
        if([self.delegate respondsToSelector:@selector(uploadManager:didChangeProgress:)]){
            [self.delegate uploadManager:self didChangeProgress:percent];
        }
    } params:nil checkCrc:NO cancellationSignal:^BOOL{
        self.uploadState = self.isCancelUpload == YES ? WTUploadStatueCanceled : WTUploadStatueUploading ;
        return self.isCancelUpload;
    }];
    
    [GetService getQiniuTokenWithBucket:bucket WithBlock:^(NSDictionary *result, NSError *error) {
        if(error){
            self.uploadState = WTUploadStatueFailed;
            if([self.delegate respondsToSelector:@selector(uploadManager:didFailedUpload:)]){
                [self.delegate uploadManager:self didFailedUpload:error];
            }
        }else{
            NSString *token = result[@"token"];
            fileType == WTFileTypeImage ? [self uploadFileWIthData:(NSData *)filePathOrData andToken:(NSString *)token] : [self uploadFileWithPath:(NSString *)filePathOrData andToken:(NSString *)token];
        }
    }];
}

- (void)uploadFileWIthData:(NSData *)data andToken:(NSString *)token
{
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    NSString * dateStr = [dateFormatter stringFromDate:[NSDate date]];
    NSString *key = [NSString stringWithFormat:@"%@/%lu%@",dateStr,data.hash,[LWUtil randomStringWithLength:4]];

    [self.uploadManager putData:data key:key token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        if(resp){
            self.uploadState = WTUploadStatueFinished;
            if([self.delegate respondsToSelector:@selector(uploadManager:didFinishedUploadWithKey:)]){
                [self.delegate uploadManager:self didFinishedUploadWithKey:key];
            }
        }else{
            if(self.uploadState != WTUploadStatueCanceled){
                self.uploadState = WTUploadStatueFailed;
                if([self.delegate respondsToSelector:@selector(uploadManager:didFailedUpload:)]){
                    [self.delegate uploadManager:self didFailedUpload:nil];
                }
            }
        }
    } option:self.uploadOption];
}

- (void)uploadFileWithPath:(NSString *)filePath andToken:(NSString *)token
{
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    NSString * dateStr = [dateFormatter stringFromDate:[NSDate date]];
    NSString *akey =  [NSString stringWithFormat:@"%@/%lu%@",dateStr,filePath.hash,[LWUtil randomStringWithLength:4]];
    NSString *key = self.fileKey.length > 0 ? self.fileKey : akey ;

    [self.uploadManager putFile:filePath key:key token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        if(resp){
            self.uploadState = WTUploadStatueFinished;
            if([self.delegate respondsToSelector:@selector(uploadManager:didFinishedUploadWithKey:)]){
                [self.delegate uploadManager:self didFinishedUploadWithKey:key];
            }
        }else{
            if(self.uploadState != WTUploadStatueCanceled){
                if(info.error.code == File_Not_Exist){
                    [self deleteCache];
                }
                self.uploadState = WTUploadStatueFailed;
                if([self.delegate respondsToSelector:@selector(uploadManager:didFailedUpload:)]){
                    [self.delegate uploadManager:self didFailedUpload:info.error];
                }
            }
        }
    } option:self.uploadOption];
}

- (void)dealloc
{
    [self.reachebility stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
