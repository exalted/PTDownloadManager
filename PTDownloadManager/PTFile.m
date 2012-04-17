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

#import "PTDownloadManager.h"
#import "AFURLConnectionOperation.h"

#define kPTLibraryInfoRequestURLStringsKey      @"urls"

////////////////////////////////////////////////////////////////////////////////
// Internal APIs
////////////////////////////////////////////////////////////////////////////////

@interface PTDownloadManager ()

@property (nonatomic, readonly) NSMutableDictionary *libraryInfo;
@property (nonatomic, readonly) NSOperationQueue *downloadQueue;

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
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[urls objectForKey:self.name]]];

    AFURLConnectionOperation *downloadOperation = [[AFURLConnectionOperation alloc] initWithRequest:request];
    [downloadOperation setDownloadProgressBlock:^(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
        NSLog(@"--");
        NSLog(@"bytesRead:                %d", bytesRead);
        NSLog(@"totalBytesRead:           %d", totalBytesRead);
        NSLog(@"totalBytesExpectedToRead: %d", totalBytesExpectedToRead);
        NSLog(@"Progress:                 %.0f%%", (float)totalBytesRead/totalBytesExpectedToRead * 100);
    }];
    [downloadOperation setCompletionBlock:^{
        NSLog(@"--");
        NSLog(@"Done.");
    }];
//    NSLog(@"Start...");
//    [foo start];

    NSLog(@"Queue download...");
    [[[PTDownloadManager sharedManager] downloadQueue] addOperation:downloadOperation];
    
    return downloadOperation;
}

@end
