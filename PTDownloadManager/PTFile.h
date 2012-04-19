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

#import <UIKit/UIKit.h>

typedef enum {
    PTFileContentStatusNone,
    PTFileContentStatusDownloading,
    PTFileContentStatusAvailable,
} PTFileContentStatus;

@interface PTFile : NSObject

// the location where file content should be stored
@property(nonatomic, readonly) NSURL *contentURL;

@property (nonatomic, readonly) PTFileContentStatus status;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSDate *date;

- (NSOperation *)download;
- (NSOperation *)downloadWithProgressOnView:(UIView *)view;

@end
