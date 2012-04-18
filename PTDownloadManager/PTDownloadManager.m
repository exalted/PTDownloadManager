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
#import "ASIHTTPRequest.h"

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

- (void)createDirectoryAtPath:(NSString *)path;
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
        _downloadQueue.showAccurateProgress = YES;
        _downloadQueue.shouldCancelAllRequestsOnFailure = NO;
        [_downloadQueue go];
    }
    return self;
}

- (NSArray *)files
{
    NSMutableArray *result = [NSMutableArray array];
    
    NSArray *allKeys = [[self.libraryInfo objectForKey:kPTLibraryInfoFilesKey] allKeys];
    for (int i = 0; i < allKeys.count; i++) {
        [result addObject:[self fileWithName:[allKeys objectAtIndex:i]]];
    }
    
    return result;
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

- (void)createDirectoryAtPath:(NSString *)path
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager createDirectoryAtPath:path
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:NULL];
    }
}

- (void)saveLibraryInfo
{
    [self createDirectoryAtPath:self.diskCachePath];
    
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:self.libraryInfo format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
    if (data) {
        [data writeToFile:[self.diskCachePath stringByAppendingPathComponent:kPTLibraryInfoFileName] atomically:YES];
    }
}

- (PTFile *)addFileWithName:(NSString *)name date:(NSDate *)date request:(NSURLRequest *)request
{
    [self createDirectoryAtPath:self.diskPath];
    
    // TODO missing implementation
    // - if exceeded 'diskCapacity', do periodic maintenance to save up some disk space, deleting oldest files in the library by their 'date'

    NSMutableDictionary *files = [self.libraryInfo objectForKey:kPTLibraryInfoFilesKey];
    NSAssert(![files objectForKey:name], @"file name is used by another file, name must be unique across all files in the library.");
    [files setObject:date forKey:name];

    NSMutableDictionary *urls = [self.libraryInfo objectForKey:kPTLibraryInfoRequestURLStringsKey];
    [urls setObject:[[request URL] absoluteString] forKey:name];

    [self saveLibraryInfo];
    
    return [[PTFile alloc] initWithName:name date:date];
}

- (void)removeFile:(PTFile *)file
{
    NSMutableDictionary *files = [self.libraryInfo objectForKey:kPTLibraryInfoFilesKey];
    NSMutableDictionary *urls = [self.libraryInfo objectForKey:kPTLibraryInfoRequestURLStringsKey];
    
    for (int i = 0; i < self.downloadQueue.requestsCount; i++) {
        ASIHTTPRequest *request = [self.downloadQueue.operations objectAtIndex:i];
        if ([request.originalURL.absoluteString isEqualToString:[urls objectForKey:file.name]]) {
            [request cancel];
            [request removeTemporaryDownloadFile];
        }
    }

    [files removeObjectForKey:file.name];
    [urls removeObjectForKey:file.name];
    
    [self saveLibraryInfo];

    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager removeItemAtURL:file.contentURL error:NULL];
}

- (PTFile *)fileWithName:(NSString *)name
{
    NSDictionary *files = [self.libraryInfo objectForKey:kPTLibraryInfoFilesKey];
    return [files objectForKey:name] ? [[PTFile alloc] initWithName:name date:[files objectForKey:name]] : nil;
}

@end
