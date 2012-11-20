//
//  AppDelegate.m
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

#import "AppDelegate.h"

@implementation AppDelegate
@synthesize menu = menu_;
@synthesize statusItem = statusItem_;
@synthesize ctx = ctx_;
@synthesize sock = sock_;
@synthesize timer = timer_;

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification {
    //Insert initialize code here
}

- (void) awakeFromNib {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    // allocate the menu
    self.menu = [NSMenu alloc];
    
    // attach the menu
    [self.statusItem setMenu:self.menu];
    [self.statusItem setHighlightMode:YES];
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"gtk_refresh" ofType:@"png"];
    NSImage * statusImage =  [[NSImage alloc] initWithContentsOfFile: imagePath];

    if (statusImage == nil) {
        NSLog(@"Error loading image");
        [self.statusItem setTitle:@"fsync"];
    }
    else {
        NSLog(@"size %f %f",statusImage.size.width, statusImage.size.height);
        [self.statusItem setImage:statusImage];
    }

    // add a separator below the quit item
    [self.menu addItem: [NSMenuItem separatorItem]];
    
    // make the about item
    NSMenuItem* aboutItem = [[NSMenuItem alloc] initWithTitle:@"About fsync" action:@selector(showAboutWebPage:) keyEquivalent:@""];
    [self.menu addItem: aboutItem];
    
    // add a separator below the quit item
    [self.menu addItem: [NSMenuItem separatorItem]];
    
    // make the quit item
    NSMenuItem* quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminateApp:) keyEquivalent:@""];
    [self.menu addItem: quitItem];
    
    [self start_zmq];
}

- (void) showAboutWebPage:(NSMenuItem*) item {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://github.com/rmcgibbo/fsync"]];
}

- (void) removeMenuItem:(NSMenuItem*) item {
    //Remove the FSEvents watch stream
    [[item representedObject] unregisterStream];
    
    // Remove the menu item
    [self.menu removeItem:item];
}

- (void) registerNewPath:(NSDictionary*)msg {
    //get sent stuff
    NSString* server_fn = [msg objectForKey:@"server_fn"];
    NSString* client_fn = [msg objectForKey:@"client_fn"];
    NSString* hostname = [msg objectForKey:@"hostname"];
    NSString* editor = [msg objectForKey:@"editor"];
    NSString* displayname = [msg objectForKey:@"displayname"];

        
    BOOL isUnique = true;
    for (NSMenuItem* item in [self.menu itemArray]) {
        if ([server_fn isEqualToString:[[item representedObject] server_fn]]) {
            isUnique = false;
        }
    }
    
    if (isUnique) {
        WatchFolder* wf = [[WatchFolder alloc] initWithServerFn:server_fn client_fn:client_fn hostname:hostname];

        NSString* title = [NSString stringWithFormat:@"%@: %@", hostname, displayname];
        NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:title action:@selector(removeMenuItem:) keyEquivalent:@""];

        [item setRepresentedObject:wf];        
        [self.menu insertItem:item atIndex:0];
    }
    
    //now launch the editor
    NSArray* args = [NSArray arrayWithObject:server_fn];     
    [NSTask launchedTaskWithLaunchPath:editor arguments:args];
}

- (void) mkdirForClient:(NSDictionary*)msg {
    NSString* dirToCreate = [msg objectForKey:@"dir"];
    
    id fm = [NSFileManager defaultManager];
    
    NSError *error = nil;    
    if(![fm fileExistsAtPath:dirToCreate])
        if(![fm createDirectoryAtPath:dirToCreate withIntermediateDirectories:YES attributes:nil error:&error])
            NSLog(@"Error: Create folder failed");
}

- (void) poll {
    NSData* msgd = [self.sock recv: ZMQ_NOBLOCK];
    if (msgd != nil) {
        NSDictionary* msg = [NSJSONSerialization JSONObjectWithData:msgd options:0 error:nil];
        NSString* type = [msg objectForKey:@"type"];
        
        if ([type isEqualToString:@"path"]) {
            [self registerNewPath:msg];
        } else if ([type isEqualToString:@"mkdir"]) {
            [self mkdirForClient:msg];
        } else {
            NSLog(@"\n\n\nBAD MESSAGE");
            NSLog(@"%@", msg);
            NSLog(@"ABORT ABORT!");
            [self terminateApp:0];
        }
        
        NSLog(@"Received: %@", msg);            
        NSData* reply = [@"OK" dataUsingEncoding: NSUTF8StringEncoding];
        [self.sock send:reply];
    }
}

- (void) start_zmq {
    // Start the ZeroMQ socket
    int a, b, c;
    [ZMQContext getZMQVersionMajor:&a minor:&b patch:&c];
    NSLog(@"ZeroMQ %d.%d.%d", a, b, c);

    self.ctx = [[ZMQContext alloc] initWithIOThreads:1];
    self.sock = [self.ctx socketWithType: ZMQ_REP];
    
    BOOL result = [self.sock bindToEndpoint:@"tcp://127.0.0.1:34401"];
    if (result) {
        NSLog(@"ZMQ bound sucessfully");
    } else {
        NSLog(@"ZMQ binding failure");
        [self terminateApp:@"Failure"];
    }
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(poll) userInfo:nil repeats:TRUE];
}


- (IBAction)terminateApp:(id)sender {
    // kill the app
    NSLog(@"Quit App!");
    [[NSApplication sharedApplication] terminate:self];
}

@end
