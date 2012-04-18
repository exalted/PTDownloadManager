//
// Copyright (C) 2012 Ali Servet Donmez. All rights reserved.
//
// This file is part of PTDownloadManager.
// modify it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// PTDownloadManager is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with PTDownloadManager. If not, see <http://www.gnu.org/licenses/>.
// PTDownloadManager is free software: you can redistribute it and/or
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

- (NSOperation *)download
{
    return [self downloadWithProgressOnView:nil];
}

- (NSOperation *)downloadWithProgressOnView:(UIView *)view
{
    NSMutableDictionary *urls = [[[PTDownloadManager sharedManager] libraryInfo] objectForKey:kPTLibraryInfoRequestURLStringsKey];
    
    ASIHTTPRequest *downloadOperation = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:[urls objectForKey:self.name]]];
    __weak ASIHTTPRequest *_request = downloadOperation;
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [downloadOperation setDownloadProgressDelegate:progressView];
    [downloadOperation setBytesReceivedBlock:^(unsigned long long size, unsigned long long total) {
//        NSLog(@"--");
//        NSLog(@"totalBytesRead:           %llu", size);
//        NSLog(@"totalBytesExpectedToRead: %llu", total);
//        NSLog(@"Progress:                 %.0f%%", (float)size/total * 100);
        NSLog(@"Progress: %.0f%%", [progressView progress] * 100);
    }];
    [downloadOperation setDownloadSizeIncrementedBlock:^(long long size) {
        NSLog(@">>> %llu", size);
    }];
    [downloadOperation setCompletionBlock:^{
        NSLog(@"--");
        NSLog(@"Done.");
    }];
    [downloadOperation setFailedBlock:^{
        NSError *error = [_request error];
        if (error) {
            NSLog(@"--");
            NSLog(@"Error: %@", [error localizedDescription]);
        }
    }];
    
    NSLog(@"Queue download...");
    [[[PTDownloadManager sharedManager] downloadQueue] addOperation:downloadOperation];
    
    return downloadOperation;
}

@end
