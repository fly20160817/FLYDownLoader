//
//  FLYFileTool.h
//  FLYDownLoader
//
//  Created by fly on 2020/3/17.
//  Copyright © 2020 fly. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLYFileTool : NSObject

//判断文件是否存在
+ (BOOL)fileExists:(NSString *)filePath;

//获取文件的大小
+ (long long)fileSize:(NSString *)filePath;

//移动文件位置
+ (void)moveFile:(NSString *)fromPath toPath:(NSString *)toPath;

//删除文件
+ (void)removeFile:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
