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
}

@property (nonatomic, retain) NSString *diskCachePath;
@property (nonatomic, retain) NSString *diskPath;

@property (nonatomic, readonly) NSMutableDictionary *libraryInfo;

- (void)createDiskCachePath;
- (void)saveLibraryInfo;

@end

@implementation PTDownloadManager

@synthesize diskCachePath = _diskCachePath;
@synthesize diskPath = _diskPath;

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
        self.diskCachePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"PTDownloadManager"];
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
        _libraryInfo = [[NSMutableDictionary alloc] initWithContentsOfFile:[[[PTDownloadManager sharedManager] diskCachePath] stringByAppendingPathComponent:kPTLibraryInfoFileName]];
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

- (void)start
{
    // TODO missing implementation
    // - if exceeded 'diskCapacity', do periodic maintenance to save up some disk space, deleting oldest files in the library by their 'date'
}

- (void)stop
{
    // TODO incomplete implementation
    // - try to finish downloading files in the background (you have 10 minutes left, tic tac...)

    [self saveLibraryInfo];
}

- (PTFile *)addFileWithName:(NSString *)name date:(NSDate *)date
{
    NSMutableDictionary *files = [self.libraryInfo objectForKey:kPTLibraryInfoFilesKey];
    
    NSAssert(![files objectForKey:name], @"file name is used by another file, name must be unique across all files in the library.");

    [files setObject:date forKey:name];
    
    return [[PTFile alloc] initWithName:name date:date];
}

@end
