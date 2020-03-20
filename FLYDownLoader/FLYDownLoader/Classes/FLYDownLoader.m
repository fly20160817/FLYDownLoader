//
//  FLYDownLoader.m
//  FLYDownLoader
//
//  Created by fly on 2020/3/17.
//  Copyright © 2020 fly. All rights reserved.
//

#import "FLYDownLoader.h"
#import "FLYFileTool.h"

#define kCachePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
#define kTmp NSTemporaryDirectory()

@interface FLYDownLoader () < NSURLSessionDelegate >
{
    long long _tmpSize;
    long long _totalSize;
}


@property (nonatomic, strong) NSURLSession * session;
@property (nonatomic, weak) NSURLSessionDataTask * dataTask;//dataTask是session里的东西，session已经对它强引用了，所以这里用weak

@property (nonatomic, strong) NSString * downLoadedPath;
@property (nonatomic, strong) NSString * downLoadingPath;
@property (nonatomic, strong) NSOutputStream * outputStream;//输出流

/**文件总大小(网络请求获取到的时候调用这个block)*/
@property (nonatomic, copy) DownLoadInfoType downLoadInfo;
/**下载进度改变调用的block*/
@property (nonatomic, copy) ProgressBlockType progressChange;
/**下载成功*/
@property (nonatomic, copy) SuccessBlockType successBlock;
/**下载失败*/
@property (nonatomic, copy) FailedBlockType failedBlock;

@end

@implementation FLYDownLoader

-(void)downLoader:(NSURL *)url
{
    //内部实现
    //1.真正的从头开始下载
    //2.如果任务存在，则实现继续下载
    
    //如果任务存在
    if ( [url isEqual:self.dataTask.originalRequest.URL] )
    {
        //判断当前的状态，如果是暂停状态
        if ( self.state == FLYDownLoaderStatePause )
        {
            //继续下载
            [self resume];
            return;
        }
        //下载中
        else if ( self.state == FLYDownLoaderStateDownLoading )
        {
            return;
        }
    }
    
    
//防止外界赋值一个url开始下载后，又赋值另一个url进行下载，这里取消上一次的url下载任务，然后下载最新的url任务
    [self cancel];
    
    
    //1.文件的存放
    //正在下载 => 放在 temp 文件夹里
    //下载完成 => 放在 cache 文件夹里
    
    NSString * fileName = url.lastPathComponent;
    
    self.downLoadedPath = [kCachePath stringByAppendingPathComponent:fileName];
    self.downLoadingPath = [kTmp stringByAppendingPathComponent:fileName];
    
    
    //1. 判断url地址对应的资源，是否下载完毕 (下载完成的目录里面，是否存在这个文件)
    //1.1 如果已经下载完毕，告诉外界下载完毕，并且传递相关信息（本地的路径，文件的大小）
    
    if ( [FLYFileTool fileExists:self.downLoadedPath] )
    {
        //告诉外界已经下载完成
        self.state = FLYDownLoaderStateSuccess;
        return;
    }
    
    
    
    //2. 检测零时文件是否存在 （下载到一半的文件）
    //2.1 不存在：从0字节开始请求资源
    
    if ( ![FLYFileTool fileExists:self.downLoadingPath] )
    {
        //从0字节开始请求资源
        [self downLoadWithURL:url offset:0];
        return;
    }
    
    
    
    //2.2 存在：直接以当前存在的文件大小，作为开始字节，去请求网络请求资源
    //    本地已下载的大小  ==  文件总大小  =>  移动到下载完成的路径中
    //    本地已下载的大小  >   文件总大小  =>  说明已下载的文件错误，删除本地缓存，从0开始下载
    //    本地已下载的大小  <   文件总大小  =>  从本地大小开始下载
    
    //获取本地大小
    _tmpSize = [FLYFileTool fileSize:self.downLoadingPath];
    [self downLoadWithURL:url offset:_tmpSize];
    
}

- (void)downLoader:(NSURL *)url downLoadInfo:(DownLoadInfoType)downLoadInfo progress:(ProgressBlockType)progressBlock success:(SuccessBlockType)successBlock failed:(FailedBlockType)failedBlock
{
    //1.给所有的block赋值
    self.downLoadInfo = downLoadInfo;
    self.progressChange = progressBlock;
    self.successBlock = successBlock;
    self.failedBlock = failedBlock;
    
    //2.开始下载
    [self downLoader:url];
}


//暂停下载 (调用了几次继续(resume)，就要调用几次暂停，才可以暂停下载，所以要用状态来控制)
- (void)pause
{
    if ( self.state == FLYDownLoaderStateDownLoading )
    {
        [self.dataTask suspend];
        self.state = FLYDownLoaderStatePause;
    }
}

//继续下载 (调用了几次暂停(suspend)，就要调用几次继续，才可以继续下载，所以要用状态来控制)
- (void)resume
{
    //判断任务存在，并且是暂停状态状态，才继续下载
    if ( self.dataTask && self.state == FLYDownLoaderStatePause )
    {
        [self.dataTask resume];
        
        self.state = FLYDownLoaderStateDownLoading;
    }
}

//取消下载
- (void)cancel
{
    //取消之后把它置空，下次用它的时候懒加载又是一个新的，防止有缓存之类的东西
    [self.session invalidateAndCancel];
    self.session = nil;
    self.state = FLYDownLoaderStatePause;
}

//取消下载并清空已下载的部分
- (void)cancelAndClean
{
    [self cancel];
    
    //清空已下载的部分
    [FLYFileTool removeFile:self.downLoadingPath];
    //不置0的话，再次点击重新下载的时候，取的还是旧值
    _tmpSize = 0;
}



#pragma mark - 私有方法

/**
 根据开始字节，请求资源
 @param url 资源地址
 @param offset 开始字节
 */
- (void)downLoadWithURL:(NSURL *)url offset:(long long)offset
{
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    //bytes=开始字节-结束字节 (-后面不写结束字节，就是一直下载到最后)
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", offset] forHTTPHeaderField:@"Range"];
    self.dataTask = [self.session dataTaskWithRequest:request];
    [self resume];
}



#pragma mark - NSURLSessionDelegate

//第一次接受到响应的时候调用（响应头信息，并没有具体的资源内容）
//通过这个方法，里面系统提供的回调代码块，可以控制是继续请求，还是取消本次请求
-(void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler
{
    //NSLog(@"response = %@", response);
    
    //文件的总大小

   /*
     "Content-Length" =     (
        4023326540
    );
    "Content-Range" =     (
        "bytes 0-4023326539/4023326540"
    );
     */ //取资源总大小：比如资源总大小是100，从10字节开始取，Content-Length的值就是90，Content-Range里才是总大小；如果从0字节开始取，Content-Length的值就是100，Content-Range字段都不会返回
    //1.从 Content-Length 取出来
    //2.如果存在 Content-Range 字段，就从这个里面取
    
    _totalSize = [((NSHTTPURLResponse *)response).allHeaderFields[@"Content-Length"] longLongValue];
    NSString * contentRangeStr = ((NSHTTPURLResponse *)response).allHeaderFields[@"Content-Range"];
    if ( contentRangeStr.length != 0 )
    {
        _totalSize = [[contentRangeStr componentsSeparatedByString:@"/"].lastObject longLongValue];
    }
    
    
    //传递给外界：资源总大小
    if ( self.downLoadInfo )
    {
        self.downLoadInfo(_totalSize);
    }
    
    
    
    //比对本地文件大小和总大小
    if ( _tmpSize == _totalSize )
    {
        //1.移动到下载完成文件夹
        [FLYFileTool moveFile:self.downLoadingPath toPath:self.downLoadedPath];
        //2.取消本次请求
        completionHandler(NSURLSessionResponseCancel);
        //3.修改状态
        self.state = FLYDownLoaderStateSuccess;
        
        return;
    }
    else if ( _tmpSize > _totalSize )
    {
        //1.删除临时缓存
        [FLYFileTool removeFile:self.downLoadingPath];
        //2.取消本次请求 (因为temp文件大于total文件，所以这次请求没必要继续走下去，所以要取消本次请求)
        completionHandler(NSURLSessionResponseCancel);
        //3.从 0 开始下载
        [self downLoader:response.URL];
        
        return;
    }
    else
    {
        /*
        NSURLSessionResponseCancel 取消请求
        NSURLSessionResponseAllow 继续请求
        */
        //继续接收数据
        self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.downLoadingPath append:YES];
        //打开输出流
        [self.outputStream open];
        completionHandler(NSURLSessionResponseAllow);
    }
}

//当用户确认，继续接收数据的时候调用
-(void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveData:(nonnull NSData *)data
{
    //NSLog(@"在接收后续数据");
    
    //当前已经下载的大小
    _tmpSize += data.length;
    
    //long类型除以long类型，结果还是long类型，所以要乘1.0精确成float类型
    self.progress = 1.0 * _tmpSize / _totalSize;
    
    [self.outputStream write:data.bytes maxLength:data.length];
}

//请求完成的时候调用（请求完成不等于请求成功）
-(void)URLSession:(NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    //NSLog(@"请求完成");
    
    if( error == nil )
    {
        /*
        下载完后进行判断，防止丢包、错位。
        判断本地下载的是否等于文件总大小
        如果等于，要验证文件是否完整（根据文件的MD5摘要值验证）
         
        需要服务器返回MD5摘要值，然后和我们下载的文件的MD5摘要值进行对比验证
        这里没服务器返回，就默认下载完是正确的了
         */
        
        [FLYFileTool moveFile:self.downLoadingPath toPath:self.downLoadedPath];
        self.state = FLYDownLoaderStateSuccess;
    }
    else
    {
        //-999是取消下载 （下载失败，可能是用户取消下载或者网络不好）
        if ( error.code == -999 )
        {
            self.state = FLYDownLoaderStatePause;
        }
        else
        {
            NSLog(@"错误： %@", error);
            self.state = FLYDownLoaderStateFailed;
        }
    }
    
    //关闭输出流
    [self.outputStream close];
}



#pragma mark - setters and getters

-(NSURLSession *)session
{
    if ( _session == nil )
    {
        NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

-(void)setState:(FLYDownLoaderState)state
{
    //相同的状态改变就过滤掉
    if ( _state == state )
    {
        return;
    }
    
    _state = state;
    
    if ( [self.delegate respondsToSelector:@selector(downLoader:didUpdateState:)] )
    {
        [self.delegate downLoader:self didUpdateState:_state];
    }
    
    
    if ( _state == FLYDownLoaderStateSuccess )
    {
        !self.successBlock ?: self.successBlock(self.downLoadedPath);
    }
    
    if ( _state == FLYDownLoaderStateFailed )
    {
        !self.failedBlock ?: self.failedBlock();
    }
}

-(void)setProgress:(float)progress
{
    _progress = progress;
    
    if( self.progressChange )
    {
        self.progressChange(_progress);
    }
}

@end


