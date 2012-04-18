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

#import "PTDownloadManager.h"

#import "ASINetworkQueue.h"

#define kPTLibraryInfoFileName                  @"libraryInfo.plist"
#define kPTLibraryInfoFilesKey                  @"files"
#define kPTLibraryInfoRequestURLStringsKey      @"urls"

////////////////////////////////////////////////////////////////////////////////
// Internal APIs
////////////////////////////////////////////////////////////////////////////////

@interface PTFile ()

@property (nonatomic) NSString *name;
@property (nonatomic) NSDate *date;

- (id)initWithName:(NSString *)name date:(NSDate *)date;

@end

////////////////////////////////////////////////////////////////////////////////
// Private
////////////////////////////////////////////////////////////////////////////////

@interface PTDownloadManager () {
    NSMutableDictionary *_libraryInfo;
    ASINetworkQueue *_downloadQueue;
}

@property (nonatomic, retain) NSString *diskCachePath;
@property (nonatomic, retain) NSString *diskPath;

@property (nonatomic, readonly) NSMutableDictionary *libraryInfo;
@property (nonatomic, readonly) ASINetworkQueue *downloadQueue;

- (void)createDiskCachePath;
- (void)saveLibraryInfo;

@end

@implementation PTDownloadManager

@synthesize diskCachePath = _diskCachePath;
@synthesize diskPath = _diskPath;
@synthesize downloadQueue = _downloadQueue;

+ (PTDownloadManager *)sharedManager
{
    static PTDownloadManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PTDownloadManager alloc] init];

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
        sharedInstance.diskPath = [paths objectAtIndex:0];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _diskCachePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"PTDownloadManager"];

        _downloadQueue = [ASINetworkQueue queue];
        _downloadQueue.shouldCancelAllRequestsOnFailure = NO;
        [_downloadQueue go];
    }
    return self;
}

- (void)dealloc
{
    [self stop];
}

- (void)changeDefaultsWithDiskCapacity:(NSUInteger)diskCapacity diskPath:(NSString *)path
{
    // TODO missing implementation
    NSAssert(diskCapacity == 0, @"disk capacity is currently unused and should be set to 0.");
    
    self.diskPath = path;
}

- (NSMutableDictionary *)libraryInfo
{
    if (!_libraryInfo) {
        _libraryInfo = [[NSMutableDictionary alloc] initWithContentsOfFile:[self.diskCachePath stringByAppendingPathComponent:kPTLibraryInfoFileName]];
        if (!_libraryInfo) {
            _libraryInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                            [NSMutableDictionary dictionary], kPTLibraryInfoFilesKey,
                            [NSMutableDictionary dictionary], kPTLibraryInfoRequestURLStringsKey,
                            nil];
        }
    }
    
    return _libraryInfo;
}

- (void)createDiskCachePath
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![fileManager fileExistsAtPath:self.diskCachePath]) {
        [fileManager createDirectoryAtPath:self.diskCachePath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:NULL];
    }
}

- (void)saveLibraryInfo
{
    [self createDiskCachePath];
    
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:self.libraryInfo format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
    if (data) {
        [data writeToFile:[self.diskCachePath stringByAppendingPathComponent:kPTLibraryInfoFileName] atomically:YES];
    }
}

- (void)stop
{
    [self saveLibraryInfo];

    // stop scheduling queued operations for execution
    [self.downloadQueue setSuspended:YES];

    // attempt to complete previously executed downloads in a background task
    __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        // application’s remaining background time reached 0: cancel all operations, clear delegates, and suspend operation
        [self.downloadQueue reset];
        
        // end the background task
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

- (PTFile *)addFileWithName:(NSString *)name date:(NSDate *)date request:(NSURLRequest *)request
{
    // TODO missing implementation
    // - if exceeded 'diskCapacity', do periodic maintenance to save up some disk space, deleting oldest files in the library by their 'date'

    NSMutableDictionary *files = [self.libraryInfo objectForKey:kPTLibraryInfoFilesKey];
//    NSAssert(![files objectForKey:name], @"file name is used by another file, name must be unique across all files in the library.");
    [files setObject:date forKey:name];

    NSMutableDictionary *urls = [self.libraryInfo objectForKey:kPTLibraryInfoRequestURLStringsKey];
    [urls setObject:[[request URL] absoluteString] forKey:name];

    [self saveLibraryInfo];
    
    return [[PTFile alloc] initWithName:name date:date];
}

@end
