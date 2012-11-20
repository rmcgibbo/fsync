//
//  AppDelegate.h
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

#import <Cocoa/Cocoa.h>
#import "ZMQObjC.h"
#import "WatchFolder.h"


@interface AppDelegate : NSObject

@property(strong, nonatomic) NSMenu* menu;
@property(strong, nonatomic) NSStatusItem* statusItem;
@property(strong, nonatomic) ZMQContext* ctx;
@property(strong, nonatomic) ZMQSocket* sock;
@property(strong, nonatomic) NSTimer* timer;


@end
