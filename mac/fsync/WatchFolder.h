//
//  WatchFolder.h
//
// Copyright 2012 Robert McGibbon
//
// This file is part of fsync
//
// fsync is free software: you can redistribute it and/or modify it under the
// terms of the GNU General Public License as published by the Free Software 
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// fsync is distributed in the hope that it will be useful, but WITHOUT ANY 
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with
// fsync. If not, see http://www.gnu.org/licenses/.

#import <Foundation/Foundation.h>

@interface WatchFolder : NSObject

@property(strong, nonatomic) NSString* server_fn;
@property(strong, nonatomic) NSString* client_fn;
@property(strong, nonatomic) NSString* hostname;
@property FSEventStreamRef stream;

- (id) initWithServerFn:(NSString *)server_fn client_fn:(NSString*) client_fn hostname:(NSString*) hostname;
- (void) unregisterStream;

@end
