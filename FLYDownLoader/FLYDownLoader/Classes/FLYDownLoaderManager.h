//
//  FLYDownLoaderManager.h
//  FLYDownLoader
//
//  Created by fly on 2020/3/20.
//  Copyright © 2020 fly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FLYDownLoader.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLYDownLoaderManager : NSObject

//单利的两种
//第一种：无论通过怎样的方式创建出来，都只有一个实例（alloc、copy、mutableCopy）
//第二种：通过某种方式，可以获取同一个对象，但是也可以通过其他方式，创建出来新的对象

+ (instancetype)shareInstance;

- (void)downLoader:(NSURL *)url downLoadInfo:(DownLoadInfoType)downLoadInfo progress:(ProgressBlockType)progressBlock success:(SuccessBlockType)successBlock failed:(FailedBlockType)failedBlock;

//暂停下载
- (void)pauseWithURL:(NSURL *)url;

//继续下载
- (void)resumeWithURL:(NSURL *)url;

//取消下载
- (void)cancelWithURL:(NSURL *)url;

//取消下载并清空已下载的部分
- (void)cancelAndCleanWithURL:(NSURL *)url;

//暂停所有下载
- (void)pauseAll;

//继续所有下载
- (void)resumeAll;

@end

NS_ASSUME_NONNULL_END
