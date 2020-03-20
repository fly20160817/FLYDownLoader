//
//  FLYFileTool.m
//  FLYDownLoader
//
//  Created by fly on 2020/3/17.
//  Copyright © 2020 fly. All rights reserved.
//

#import "FLYFileTool.h"

@implementation FLYFileTool

+ (BOOL)fileExists:(NSString *)filePath
{
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

+ (long long)fileSize:(NSString *)filePath
{
    //先判断文件是否存在
    if ( ![self fileExists:filePath] )
    {
        return 0;
    }
    
    //获取文件属性
    NSDictionary * fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    
    return [fileInfo[NSFileSize] longLongValue];
}

+ (void)moveFile:(NSString *)fromPath toPath:(NSString *)toPath
{
    [[NSFileManager defaultManager] moveItemAtPath:fromPath toPath:toPath error:nil];
}

+ (void)removeFile:(NSString *)filePath
{
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
}

@end
