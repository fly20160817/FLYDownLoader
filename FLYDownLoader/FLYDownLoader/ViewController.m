//
//  ViewController.m
//  FLYDownLoader
//
//  Created by fly on 2020/3/17.
//  Copyright © 2020 fly. All rights reserved.
//

#import "ViewController.h"
#import "FLYDownLoaderManager.h"

@interface ViewController () < FLYDownLoaderDelegate >

@property (nonatomic, strong) NSArray * urlArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

//下载
- (IBAction)download:(id)sender {
    
    [[FLYDownLoaderManager shareInstance] downLoader:self.urlArray[0] downLoadInfo:^(long long totalSize) {
        
        NSLog(@"111下载信息--总大小：%lld", totalSize);
        
    } progress:^(float progress) {
        
        NSLog(@"111下载进度：%.2f%%", progress * 100);
        
    } success:^(NSString * _Nonnull filePath) {
        
        NSLog(@"111下载成功：%@", filePath);
        
    } failed:^{
        
        NSLog(@"111下载失败");
        
    }];
    
    
    
    
    [[FLYDownLoaderManager shareInstance] downLoader:self.urlArray[1] downLoadInfo:^(long long totalSize) {
        
        NSLog(@"222下载信息--总大小：%lld", totalSize);
        
    } progress:^(float progress) {
        
        NSLog(@"222下载进度：%.2f%%", progress * 100);
        
    } success:^(NSString * _Nonnull filePath) {
        
        NSLog(@"222下载成功：%@", filePath);
        
    } failed:^{
        
        NSLog(@"222下载失败");
        
    }];
    
}

//暂停
- (IBAction)pause:(id)sender {
    
    [[FLYDownLoaderManager shareInstance] pauseWithURL:self.urlArray[0]];
}

//取消
- (IBAction)cancel:(id)sender {
    
    [[FLYDownLoaderManager shareInstance] cancelWithURL:self.urlArray[0]];
}

//取消并删除已下载部分
- (IBAction)cancelAndClean:(id)sender {
    
    [[FLYDownLoaderManager shareInstance] cancelAndCleanWithURL:self.urlArray[0]];
}



#pragma mark - FLYDownLoaderDelegate

-(void)downLoader:(FLYDownLoader *)downLoader didUpdateState:(FLYDownLoaderState)state
{
    NSLog(@"下载状态改变了：%lu", (unsigned long)state);
}



#pragma mark - setters and getter

-(NSArray *)urlArray
{
    if ( _urlArray == nil )
    {
        NSURL * url1 = [NSURL URLWithString:@"http://updates-http.cdn-apple.com/2020WinterSeed/fullrestores/061-87409/FC508F47-6765-4B95-B838-2D5CB47EF05D/iPhone_4.7_P3_13.4_17E5255a_Restore.ipsw"];
        NSURL * url2 = [NSURL URLWithString:@"http://updates-http.cdn-apple.com/2020WinterFCS/fullrestores/041-43668/21C6BAA8-64B4-11EA-9EF9-C607EA8B25A1/AppleTV5,3_13.4_17L256_Restore.ipsw"];
        
        _urlArray = @[url1, url2];
    }
    return _urlArray;
}


@end
