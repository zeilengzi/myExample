//
//  AppDelegate.h
//  DownloadTask
//
//  Created by Jymn_Chen on 14-2-5.
//  Copyright (c) 2014年 Jymn_Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

+ (instancetype)sharedDelegate;

@property (strong, nonatomic) UIWindow *window;

/* 用于保存后台下载任务完成后的回调代码块 */
@property (copy) void (^backgroundURLSessionCompletionHandler)();

@end
