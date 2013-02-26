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

////////////////////////////////////////////////////////////////////////////////
// Internal APIs
////////////////////////////////////////////////////////////////////////////////

@interface PTDownloadManager ()

- (ASIHTTPRequest *)requestForFile:(PTFile *)file;

@end

////////////////////////////////////////////////////////////////////////////////
// Private
////////////////////////////////////////////////////////////////////////////////

@interface PTFile ()

@property UIProgressView *progressView;
@property UILabel *label;
@property NSString *savedLabelText;

- (id)initWithName:(NSString *)name date:(NSDate *)date;

- (void)updateStatusForRequest:(ASIHTTPRequest *)request;

@end

@implementation PTFile

@synthesize name = _name;
@synthesize date = _date;
@synthesize progressView = _progressView;
@synthesize label = _label;
@synthesize savedLabelText = _savedLabelText;

- (id)initWithName:(NSString *)name date:(NSDate *)date
{
    self = [super init];
    if (self) {
        _name = name;
        _date = date;
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    }
    return self;
}

- (NSURL *)contentURL
{
    return [NSURL fileURLWithPath:[[[PTDownloadManager sharedManager] requestForFile:self] downloadDestinationPath]];
}

- (PTFileContentStatus)status
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:[self.contentURL path]]) {
        return PTFileContentStatusAvailable;
    }
    else {
        ASIHTTPRequest *request = [[PTDownloadManager sharedManager] requestForFile:self];
        if (request && request.isExecuting) {
            return PTFileContentStatusDownloading;
        }
    }
    
    return PTFileContentStatusNone;
}

- (NSOperation *)download
{
    // Why '__unsafe_unretained'? See: http://stackoverflow.com/questions/4352561/retain-cycle-on-self-with-blocks
    __unsafe_unretained ASIHTTPRequest *downloadOperation = [[PTDownloadManager sharedManager] requestForFile:self];
    NSAssert(downloadOperation.userInfo && [downloadOperation.userInfo objectForKey:@"queue"], @"download is currently executing or has already finished executing.");
    
    [downloadOperation setStartedBlock:^{
        [self updateStatusForRequest:downloadOperation];
    }];
    [downloadOperation setFailedBlock:^{
        [self updateStatusForRequest:downloadOperation];
    }];
    [downloadOperation setCompletionBlock:^{
        [self updateStatusForRequest:downloadOperation];
    }];

    [downloadOperation setDownloadProgressDelegate:self.progressView];

    [(ASINetworkQueue *)[downloadOperation.userInfo objectForKey:@"queue"] addOperation:downloadOperation];
    
    // we don't want to expose userInfo externally
    downloadOperation.userInfo = nil;

    return downloadOperation;
}

- (void)showProgressOnView:(UIView *)view label:(UILabel *)label
{
    [self updateStatusForRequest:nil];
    
    // TODO give users an option tuning this to any CGFloat value as they wish
    static CGFloat margin = 5.0;
    if (view) {
        self.progressView.frame = CGRectMake(margin,
                                             view.bounds.size.height - self.progressView.frame.size.height - margin,
                                             view.bounds.size.width - margin * 2,
                                             self.progressView.frame.size.height);
        [view addSubview:self.progressView];
    }
    
    if (label) {
        self.label = label;
        self.savedLabelText = label.text;
    }
    
    [self updateStatusForRequest:[[PTDownloadManager sharedManager] requestForFile:self]];
}

- (void)updateStatusForRequest:(ASIHTTPRequest *)request
{
    if (!request || request.isCancelled || request.isFinished) {
        [self.progressView removeFromSuperview];
        self.label.text = self.savedLabelText;

        [self.delegate fileDidFinishDownloading:self];
    }
    else if (request.isExecuting) {
        self.label.text = NSLocalizedString(@"Loading...", nil);
    }
    else if (request.isReady) {
        self.label.text = NSLocalizedString(@"Waiting...", nil);
    }
}

@end
