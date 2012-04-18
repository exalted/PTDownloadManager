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
