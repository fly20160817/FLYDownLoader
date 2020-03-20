//
//  FLYDownLoader.h
//  FLYDownLoader
//
//  Created by fly on 2020/3/17.
//  Copyright © 2020 fly. All rights reserved.
//

//一个下载器(FLYDownLoader)，对应一个下载任务

#import <Foundation/Foundation.h>

@class FLYDownLoader;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FLYDownLoaderState) {
    FLYDownLoaderStatePause,          //下载暂停/取消
    FLYDownLoaderStateDownLoading,    //下载中
    FLYDownLoaderStateSuccess,        //下载完成
    FLYDownLoaderStateFailed          //下载失败
};

typedef void(^DownLoadInfoType)(long long totalSize);
typedef void(^ProgressBlockType)(float progress);
typedef void(^SuccessBlockType)(NSString *filePath);
typedef void(^FailedBlockType)(void);

@protocol FLYDownLoaderDelegate <NSObject>

-(void)downLoader:(FLYDownLoader *)downLoader didUpdateState:(FLYDownLoaderState)state;

@end


@interface FLYDownLoader : NSObject

/**下载的状态*/
@property (nonatomic, assign, readonly) FLYDownLoaderState state;
/**下载进度*/
@property (nonatomic, assign, readonly) float progress;
/**代理*/
@property (nonatomic, weak) id<FLYDownLoaderDelegate> delegate;


//下载
- (void)downLoader:(NSURL *)url;

- (void)downLoader:(NSURL *)url downLoadInfo:(DownLoadInfoType)downLoadInfo progress:(ProgressBlockType)progressBlock success:(SuccessBlockType)successBlock failed:(FailedBlockType)failedBlock;

//暂停下载
- (void)pause;

//继续下载
- (void)resume;

//取消下载
- (void)cancel;

//取消下载并清空已下载的部分
- (void)cancelAndClean;

@end

NS_ASSUME_NONNULL_END
