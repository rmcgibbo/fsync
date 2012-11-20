//
//  WatchFolder.m
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
#import "WatchFolder.h"


@implementation WatchFolder
@synthesize server_fn = server_fn_;
@synthesize client_fn = client_fn_;
@synthesize hostname = hostname_;
@synthesize stream = stream_;

static void callback(ConstFSEventStreamRef streamRef, void* pClientCallBackInfo, size_t numEvents, void* pEventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
    //This is like an instance method, since pClientCallBackInfo contains the WatchFolder instance
    WatchFolder* self = (__bridge WatchFolder*) pClientCallBackInfo;
    
    // execute rsync
    // puts "rsync -r #{server_fn} #{client_hostname}:#{client_fn}"    
    NSString* bin = @"/usr/bin/rsync";
    NSArray* args = [NSArray arrayWithObjects:@"-r", self.server_fn, [NSString stringWithFormat:@"%@:%@", self.hostname, self.client_fn], nil];
    
    NSLog(@"Rsyncing %@ %@", bin, args);
    [[NSTask launchedTaskWithLaunchPath:bin arguments:args] waitUntilExit];
    NSLog(@"Rsync Completed!");
}


- (id) initWithServerFn:(NSString *)server_fn client_fn:(NSString*) client_fn hostname:(NSString*) hostname  {
    self.server_fn = server_fn;
    self.client_fn = client_fn;
    self.hostname = hostname;
    
    NSLog(@"Server fn: %@", server_fn);
    
    // if its a file, we need to put a watch on its enclosing
    // directory
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:server_fn isDirectory:&isDir];
    if (!exists) {
        NSLog(@"File doesn't exist!");
    }
    
    NSString* dir = server_fn;
    if (!isDir)
        dir = [server_fn stringByDeletingLastPathComponent];
    
    //fs events wants an array of the path(s) to watch
    NSArray* paths = [NSArray arrayWithObject:dir];
    
    // make the context for the callback. We pass a pointer to
    // self, so that it will be like an instance method
    FSEventStreamContext cntx;
    cntx.version = 0;
    cntx.info = (__bridge void*)self;
    cntx.retain = NULL;
    cntx.release = NULL;
    cntx.copyDescription = NULL;
    
    NSLog(@"Adding a watch on: %@", paths);
        
    self.stream = FSEventStreamCreate(NULL, &callback, &cntx, (__bridge CFArrayRef) paths, kFSEventStreamEventIdSinceNow, 1, kFSEventStreamCreateFlagWatchRoot);
    
    FSEventStreamScheduleWithRunLoop(self.stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(self.stream);
    
    return self;
}

- (void) unregisterStream {
    FSEventStreamStop(self.stream);
    FSEventStreamRelease(self.stream);
}


@end
