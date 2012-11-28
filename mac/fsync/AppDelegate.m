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
@synthesize topSeparator = topSeparator_;
@synthesize animTimer = animTimer_;
@synthesize statusImages = statusImages_;

- (void) awakeFromNib {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:21];
    // allocate the menu
    self.menu = [NSMenu alloc];
    
    // attach the menu
    [self.statusItem setMenu:self.menu];
    [self.statusItem setHighlightMode:YES];
    
    //load the images
    self.statusImages = [self loadImages];
    self->n_rsyncs = 0;
    [self stopRsyncIndicator:nil]; //sets the image
        

    // top separator, above which the separate paths will be (below which is the about stuff
    self.topSeparator = [NSMenuItem separatorItem];
    [self.topSeparator setHidden: YES];
    [self.menu addItem: self.topSeparator];
    
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

- (NSArray*) loadImages {
    // load all of the images
    NSString* imagePath;
    NSImage* statusImage;
    NSSize imageSize;
    NSMutableArray* images = [[NSMutableArray alloc] initWithCapacity:72];
    NSFileManager* fm = [NSFileManager defaultManager];

    for (int i = 0; i < 72; i+=1) {
        imagePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"refresh_small_%d", 5*i] ofType:@"png"];

        if (![fm fileExistsAtPath:imagePath]) {
            NSLog(@"Error!");
        }

        statusImage =  [[NSImage alloc] initWithContentsOfFile: imagePath];

        imageSize.width = 18;
        imageSize.height = 18;
        [statusImage setSize:imageSize];

        [images insertObject:statusImage atIndex:i];
    }

    return [[NSArray alloc] initWithArray:images];
}

- (void)startRsyncIndicator:(id) sender {
    // start the gui indicator of a progressing rsync
    // the indicator is the rotating of the icon
    // call this whenever you start an rsync
    
    self->currentFrame = 0;
    if (self->n_rsyncs == 0) {
        self.animTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/15.0 target:self selector:@selector(animateTick:) userInfo:nil repeats:YES];
    }
    
    self->n_rsyncs++;
}

- (void)stopRsyncIndicator:(id) sender {
    // stop the gui indicator of the progressing rsync
    // this only ACTUALLY stops the indicator if there
    // are NO currently progressing rsyncs.
    // call this whenever you stop an rsync
    
    self->n_rsyncs--;
    
    // keep it in valid teritory
    if (self->n_rsyncs < 0)
        self->n_rsyncs = 0;
    
    // only stop the animation loop if the number
    // of outstanding rsyncs is zero
    if (self->n_rsyncs == 0) {
        [self.animTimer invalidate];
        self->currentFrame = 0;
        [self.statusItem setImage:[self.statusImages objectAtIndex:0]];
    }
}

- (void) animateTick:(NSTimer*) timer {
    NSImage* image = [self.statusImages objectAtIndex:self->currentFrame];
    [self.statusItem setImage:image];
    self->currentFrame += 1;
    self->currentFrame %= [self.statusImages count];
}

- (void) showAboutWebPage:(NSMenuItem*) item {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://github.com/rmcgibbo/fsync"]];
}

- (void) removeMenuItem:(NSMenuItem*) item {
    //Remove the FSEvents watch stream
    [[item representedObject] unregisterStream];
    
    // Remove the menu item
    [self.menu removeItem:item];

    // if there are no items being watched, hide the top separator
    if ([self.menu numberOfItems] <= 4) {
        //three items being "Quit", "About" and the separator between them
        [self.topSeparator setHidden:YES];
    }

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

        // if we're adding menu items, make sure that the separator which
        // comes above
        [self.topSeparator setHidden:NO];
    }
    
    //launch the editor shell command
    [self performSelectorInBackground:@selector(launchEditor:) withObject:[NSArray arrayWithObjects:editor, server_fn, nil]];
}

- (void) raiseAlert:(NSString*) msg {
    // hack: remove the first item, from the list
    // really should remove the *correct* item, but it's likely to be the first.
    [self removeMenuItem: [[self.menu itemArray] objectAtIndex:0]];

    NSAlert* alert = [NSAlert alertWithMessageText:@" Error" defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:msg];
    [alert runModal];
}

- (void) launchEditor:(NSArray*) editorPathAndArg {
    //editorPathAndArg should be an array with the editor at index 0 and the filename to open at index 1

    assert ([editorPathAndArg count] == 2);
    NSString* editorPath = [editorPathAndArg objectAtIndex:0];
    NSString* arg = [editorPathAndArg objectAtIndex:1];

    NSString* absEditorPath;

    //check if editor is an absolute path
    if (![editorPath hasPrefix:@"/"]) {
        NSString* pathEnvVar = [[[NSProcessInfo processInfo] environment] objectForKey:@"PATH"];

        absEditorPath = [self searchFileInPath:editorPath searchPath:pathEnvVar];
        if (absEditorPath == nil) {
            NSString* msg = [[NSString alloc] initWithFormat:@"The executable '%@' was not found in the $PATH", editorPath]; 
            [self performSelectorOnMainThread:@selector(raiseLaunchAlert:) withObject:msg waitUntilDone:FALSE];
            return;
        }
    } else {
        absEditorPath = editorPath;
    }

    NSTask* task = [NSTask new];
    NSPipe* pipe = [NSPipe pipe];

    [task setLaunchPath:absEditorPath];
    [task setArguments:[NSArray arrayWithObject:arg]];
    [task setStandardError:pipe];
    [task launch];
    [task waitUntilExit];

    if ([task terminationStatus] != 0) {
        NSData* stderrData = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString* stderr =[[NSString alloc] initWithData:stderrData encoding:NSUTF8StringEncoding];
        [self performSelectorOnMainThread: @selector(raiseLaunchAlert:) withObject:stderr waitUntilDone:FALSE];
    }
}

- (NSString*) searchFileInPath:(NSString*) filename searchPath:(NSString*) searchPath {
    //Search for a file in a bunch of ':' directorys (i.e. $PATH)
    NSFileManager *fileManager = [NSFileManager defaultManager];

    for (NSString* path in [searchPath componentsSeparatedByString: @":"]) {
        NSString* candidate = [[NSString alloc] initWithFormat: @"%@/%@", path, filename];
        BOOL exists = [fileManager fileExistsAtPath: candidate];
        if (exists) {
            return [candidate stringByStandardizingPath];
        }
    }
    return nil;
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
    
    BOOL result = [self.sock bindToEndpoint:@"tcp://*:34401"];
    if (result) {
        NSLog(@"ZMQ bound sucessfully");
    } else {
        NSAlert* alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"Quit" alternateButton:nil otherButton:nil informativeTextWithFormat:@"ZeroMQ Binding Failure. Is the port already in use?"];    
        [alert runModal];
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
