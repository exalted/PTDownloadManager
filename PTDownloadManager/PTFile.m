//
// Copyright (C) 2012 Ali Servet Donmez. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "PTFile.h"

#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"

#import "PTDownloadManager.h"

#define kPTLibraryInfoRequestURLStringsKey      @"urls"

////////////////////////////////////////////////////////////////////////////////
// Internal APIs
////////////////////////////////////////////////////////////////////////////////

@interface PTDownloadManager ()

@property (nonatomic, readonly) NSString *diskCachePath;
@property (nonatomic, readonly) NSString *diskPath;

@property (nonatomic, readonly) NSMutableDictionary *libraryInfo;
@property (nonatomic, readonly) ASINetworkQueue *downloadQueue;

@end

////////////////////////////////////////////////////////////////////////////////
// Private
////////////////////////////////////////////////////////////////////////////////

@interface PTFile ()

- (id)initWithName:(NSString *)name date:(NSDate *)date;

@end

@implementation PTFile

@synthesize name = _name;
@synthesize date = _date;

- (id)initWithName:(NSString *)name date:(NSDate *)date
{
    self = [super init];
    if (self) {
        _name = name;
        _date = date;
    }
    return self;
}

- (NSURL *)contentURL
{
    return [NSURL fileURLWithPath:[[[PTDownloadManager sharedManager] diskPath] stringByAppendingPathComponent:self.name]];
}

- (PTFileContentStatus)status
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:[self.contentURL path]]) {
        return PTFileContentStatusAvailable;
    }
    else {
        NSMutableDictionary *urls = [[[PTDownloadManager sharedManager] libraryInfo] objectForKey:kPTLibraryInfoRequestURLStringsKey];
        for (int i = 0; i < [[[PTDownloadManager sharedManager] downloadQueue] requestsCount]; i++) {
            ASIHTTPRequest *request = [[[[PTDownloadManager sharedManager] downloadQueue] operations] objectAtIndex:i];
            if ([request.originalURL.absoluteString isEqualToString:[urls objectForKey:self.name]]) {
                if ([request isExecuting]) {
                    return PTFileContentStatusDownloading;
                }
            }
        }
    }
    
    return PTFileContentStatusNone;
}

- (NSOperation *)download
{
    return [self downloadWithProgressOnView:nil];
}

- (NSOperation *)downloadWithProgressOnView:(UIView *)view
{
    NSMutableDictionary *urls = [[[PTDownloadManager sharedManager] libraryInfo] objectForKey:kPTLibraryInfoRequestURLStringsKey];
    
    ASIHTTPRequest *downloadOperation = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:[urls objectForKey:self.name]]];
    downloadOperation.temporaryFileDownloadPath = [[[[PTDownloadManager sharedManager] diskCachePath] stringByAppendingPathComponent:self.name] stringByAppendingPathExtension:@"download"];
    downloadOperation.downloadDestinationPath = [[[PTDownloadManager sharedManager] diskPath] stringByAppendingPathComponent:self.name];
    downloadOperation.allowResumeForFileDownloads = YES;
    downloadOperation.shouldContinueWhenAppEntersBackground = YES;
    // TODO remove duplicate
    // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    [downloadOperation setCompletionBlock:^{
        if (view) {
            for (UIView *subView in view.subviews) {
                if ([subView isKindOfClass:[UIProgressView class]]) {
                    [subView removeFromSuperview];
                    break;
                }
            }
        }
    }];
    [downloadOperation setFailedBlock:^{
        if (view) {
            for (UIView *subView in view.subviews) {
                if ([subView isKindOfClass:[UIProgressView class]]) {
                    [subView removeFromSuperview];
                    break;
                }
            }
        }
    }];
    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    if (view) {
        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        progressView.frame = CGRectMake(5.0,
                                        view.bounds.size.height - progressView.frame.size.height - 5.0,
                                        view.bounds.size.width - 10.0,
                                        progressView.frame.size.height);
        [view addSubview:progressView];

        [downloadOperation setDownloadProgressDelegate:progressView];
    }

    [[[PTDownloadManager sharedManager] downloadQueue] addOperation:downloadOperation];
    
    return downloadOperation;
}

@end
