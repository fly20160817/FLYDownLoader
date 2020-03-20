//
//  FLYDownLoaderManager.m
//  FLYDownLoader
//
//  Created by fly on 2020/3/20.
//  Copyright © 2020 fly. All rights reserved.
//

#import "FLYDownLoaderManager.h"
#import "NSString+SZ.h"

@interface FLYDownLoaderManager () <NSCopying, NSMutableCopying>

//存放多个下载任务的字典   key: md5(url)  value: FLYDownLoader
@property (nonatomic, strong) NSMutableDictionary * downLoaderDict;

@end

@implementation FLYDownLoaderManager

#pragma mark - 单利 （保证无论通过怎样的方式创建出来，都只有一个实例）

static FLYDownLoaderManager * _shareInstance;

+ (instancetype)shareInstance
{
    if ( _shareInstance == nil )
    {
        _shareInstance = [[self alloc] init];
    }
    return _shareInstance;
}

//分配内存地址的时候调用 (当执行alloc的时候，系统会自动调用分配内存地址的方法)
+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    if ( !_shareInstance )
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _shareInstance = [super allocWithZone:zone];
        });
    }
    return _shareInstance;
}


//保证copy这个对象的时候，返回的还是这个单利，不会生成新的 (这个方法需要在头部声明代理)
-(id)copyWithZone:(NSZone *)zone
{
    return _shareInstance;
}

//保证copy这个对象的时候，返回的还是这个单利，不会生成新的 (这个方法需要在头部声明代理)
-(id)mutableCopyWithZone:(NSZone *)zone
{
    return _shareInstance;
}



#pragma mark - downLoader

- (void)downLoader:(NSURL *)url downLoadInfo:(DownLoadInfoType)downLoadInfo progress:(ProgressBlockType)progressBlock success:(SuccessBlockType)successBlock failed:(FailedBlockType)failedBlock
{
    //1.url
    NSString * urlMD5 = [url.absoluteString md5];
    
    //2.根据 urlMD5 查找相应的下载器
    FLYDownLoader * downLoader = self.downLoaderDict[urlMD5];
    
    if ( downLoader == nil )
    {
        downLoader = [[FLYDownLoader alloc] init];
        self.downLoaderDict[urlMD5] = downLoader;
    }
    
    [downLoader downLoader:url downLoadInfo:downLoadInfo progress:progressBlock success:^(NSString * _Nonnull filePath) {
        
        //下载成功后移除
        [self.downLoaderDict removeObjectForKey:urlMD5];
        
        successBlock(filePath);
        
    } failed:failedBlock];
}

//暂停下载
- (void)pauseWithURL:(NSURL *)url
{
    NSString * urlMD5 = [url.absoluteString md5];
    FLYDownLoader * downLoader = self.downLoaderDict[urlMD5];
    [downLoader pause];
}

//继续下载
- (void)resumeWithURL:(NSURL *)url
{
    NSString * urlMD5 = [url.absoluteString md5];
    FLYDownLoader * downLoader = self.downLoaderDict[urlMD5];
    [downLoader resume];
}

//取消下载
- (void)cancelWithURL:(NSURL *)url
{
    NSString * urlMD5 = [url.absoluteString md5];
    FLYDownLoader * downLoader = self.downLoaderDict[urlMD5];
    [downLoader cancel];
}

//取消下载并清空已下载的部分
- (void)cancelAndCleanWithURL:(NSURL *)url
{
    NSString * urlMD5 = [url.absoluteString md5];
    FLYDownLoader * downLoader = self.downLoaderDict[urlMD5];
    [downLoader cancelAndClean];
}

//暂停所有下载
- (void)pauseAll
{
    [self.downLoaderDict.allValues makeObjectsPerformSelector:@selector(pause) withObject:nil];
}

//继续所有下载
- (void)resumeAll
{
    [self.downLoaderDict.allValues makeObjectsPerformSelector:@selector(resume) withObject:nil];
}



#pragma mark - setters and getters

-(NSMutableDictionary *)downLoaderDict
{
    if ( _downLoaderDict == nil )
    {
        _downLoaderDict = [NSMutableDictionary dictionary];
    }
    return _downLoaderDict;
}

@end
