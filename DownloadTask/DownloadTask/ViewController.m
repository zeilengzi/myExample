//
//  ViewController.m
//  DownloadTask
//
//  Created by Jymn_Chen on 14-2-5.
//  Copyright (c) 2014年 Jymn_Chen. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

#pragma mark - Constants

static NSString * const kCurrentSession      = @"Current Session";
static NSString * const kBackgroundSession   = @"Background Session";
static NSString * const kBackgroundSessionID = @"cn.edu.scnu.DownloadTask.BackgroundSession";

@interface ViewController ()

@end

@implementation ViewController

#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setDownloadProgress:0.0];
    self.downloadedImageView.image = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/* 根据下载进度更新视图 */
- (void)setDownloadProgress:(double)progress {
    NSString *progressStr = [NSString stringWithFormat:@"%.1f", progress * 100];
    progressStr = [progressStr stringByAppendingString:@"%"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.downloadingProgressView.progress = progress;
        self.currentProgress_label.text = progressStr;
    });
}

#pragma mark - Button Actions

- (IBAction)cancellableDownload:(id)sender {
    if (!self.cancellableTask) {
        if (!self.currentSession) {
            [self createCurrentSession];
        }
        
        NSString *imageURLStr = @"http://farm6.staticflickr.com/5505/9824098016_0e28a047c2_b_d.jpg";
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURLStr]];
        self.cancellableTask = [self.currentSession downloadTaskWithRequest:request];
        
        [self setDownloadButtonsWithEnabled:NO];
        self.downloadedImageView.image = nil;
        
        [self.cancellableTask resume];
    }
}

- (IBAction)resumableDownload:(id)sender {
    if (!self.resumableTask) {
        if (!self.currentSession) {
            [self createCurrentSession];
        }
        
        if (self.partialData) { // 如果是之前被暂停的任务，就从已经保存的数据恢复下载
            self.resumableTask = [self.currentSession downloadTaskWithResumeData:self.partialData];
        }
        else { // 否则创建下载任务
            NSString *imageURLStr = @"http://farm3.staticflickr.com/2846/9823925914_78cd653ac9_b_d.jpg";
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURLStr]];
            self.resumableTask = [self.currentSession downloadTaskWithRequest:request];
        }
        
        [self setDownloadButtonsWithEnabled:NO];
        self.downloadedImageView.image = nil;
        
        [self.resumableTask resume];
    }
}

- (IBAction)backgroundDownload:(id)sender {
    NSString *imageURLStr = @"http://farm3.staticflickr.com/2831/9823890176_82b4165653_b_d.jpg";
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURLStr]];
    self.backgroundTask = [self.backgroundSession downloadTaskWithRequest:request];
    
    [self setDownloadButtonsWithEnabled:NO];
    self.downloadedImageView.image = nil;
    
    [self.backgroundTask resume];
}

- (IBAction)cancelDownloadTask:(id)sender {
    if (self.cancellableTask) {
        [self.cancellableTask cancel];
        self.cancellableTask = nil;
    }
    else if (self.resumableTask) {
        [self.resumableTask cancelByProducingResumeData:^(NSData *resumeData) {
            // 如果是可恢复的下载任务，应该先将数据保存到partialData中，注意在这里不要调用cancel方法
            self.partialData = resumeData;
            self.resumableTask = nil;
        }];
    }
    else if (self.backgroundTask) {
        [self.backgroundTask cancel];
        self.backgroundTask = nil;
    }
    
    [self setDownloadProgress:0.0];
    self.downloadedImageView.image = nil;
}

- (void)setDownloadButtonsWithEnabled:(BOOL)enabled {
    self.cancellableDownload_barButtonItem.enabled = enabled;
    self.resumableDownload_barButtonItem.enabled   = enabled;
    self.backgroundDownload_barButtonItem.enabled  = enabled;
}

#pragma mark - Get sessions

/* 创建当前的session */
- (void)createCurrentSession {
    NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.currentSession = [NSURLSession sessionWithConfiguration:defaultConfig delegate:self delegateQueue:nil];
    self.currentSession.sessionDescription = kCurrentSession;
}

/* 创建一个后台session单例 */
- (NSURLSession *)backgroundSession {
    static NSURLSession *backgroundSess = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:kBackgroundSessionID];
        backgroundSess = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
        backgroundSess.sessionDescription = kBackgroundSession;
    });
    
    return backgroundSess;
}

#pragma mark - NSURLSessionDownloadDelegate

/* 执行下载任务时有数据写入 */
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten // 每次写入的data字节数
 totalBytesWritten:(int64_t)totalBytesWritten // 当前一共写入的data字节数
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite // 期望收到的所有data字节数
{
    // 计算当前下载进度并更新视图
    double downloadProgress = totalBytesWritten / (double)totalBytesExpectedToWrite;
    [self setDownloadProgress:downloadProgress];
}

/* 从fileOffset位移处恢复下载任务 */
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    NSLog(@"NSURLSessionDownloadDelegate: Resume download at %lld", fileOffset);
}

/* 完成下载任务，只有下载成功才调用该方法 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"NSURLSessionDownloadDelegate: Finish downloading");
    
    // 1.将下载成功后的文件移动到目标路径
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *URLs = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = URLs[0];
    NSURL *destinationPath = [documentsDirectory URLByAppendingPathComponent:[location lastPathComponent]];
    
    if ([fileManager fileExistsAtPath:[destinationPath path] isDirectory:NULL]) {
        [fileManager removeItemAtURL:destinationPath error:NULL];
    }
    
    NSError *error = nil;
    if ([fileManager moveItemAtURL:location toURL:destinationPath error:&error]) {
        // 2.刷新视图，显示下载后的图片
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setDownloadProgress:1.0];
            UIImage *image = [UIImage imageWithContentsOfFile:[destinationPath path]];
            self.downloadedImageView.image = image;
        });
    }
    
    // 3.取消已经完成的下载任务
    if (downloadTask == self.cancellableTask) {
        self.cancellableTask = nil;
    }
    else if (downloadTask == self.resumableTask) {
        self.resumableTask = nil;
        self.partialData = nil;
    }
    else if (session == self.backgroundSession) {
        self.backgroundTask = nil;
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        if (appDelegate.backgroundURLSessionCompletionHandler) {
            // 执行回调代码块
            void (^handler)() = appDelegate.backgroundURLSessionCompletionHandler;
            appDelegate.backgroundURLSessionCompletionHandler = nil;
            handler();
        }
    }
}

/* 完成下载任务，无论下载成功还是失败都调用该方法 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"NSURLSessionDownloadDelegate: Complete task");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setDownloadButtonsWithEnabled:YES];
    });
    
    if (error) {
        NSLog(@"下载失败：%@", error);
        [self setDownloadProgress:0.0];
        self.downloadedImageView.image = nil;
    }
}

@end
