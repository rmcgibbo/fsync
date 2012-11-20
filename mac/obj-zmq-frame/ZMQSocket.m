#import "ZMQSocket.h"
#import "ZMQContext.h"

enum {
	ZMQ_SOCKET_OPTION_MAX_LENGTH = 255,  // ZMQ_IDENTITY
};

@interface ZMQContext (ZMQSocketIsFriend)
@property(readonly) void *context;
@end

@interface ZMQSocket ()
@property(readwrite, getter=isClosed, NS_NONATOMIC_IPHONEONLY) BOOL closed;
@property(readonly) void *socket;
@property(readwrite, copy, NS_NONATOMIC_IPHONEONLY) NSString *endpoint;
@end

static inline void ZMQLogError(id object, NSString *msg);

@implementation ZMQSocket
+ (NSString *)nameForSocketType:(ZMQSocketType)type {
	static NSString *const typeNames[] = {
		@"ZMQ_PAIR",
		@"ZMQ_PUB", @"ZMQ_SUB",
		@"ZMQ_REQ", @"ZMQ_REP",
		@"ZMQ_XREQ", @"ZMQ_XREP",
		@"ZMQ_PULL", @"ZMQ_PUSH"
	};
	static const ZMQSocketType
			typeNameCount = sizeof(typeNames)/sizeof(*typeNames);

	if (type < 0 || type >= typeNameCount) return @"UNKNOWN";
	return typeNames[type];
}

- (id)init {
	NSString *
	err = [NSString stringWithFormat:
	       @"%s: *** Create sockets using -[ZMQContext socketWithType:].",
	       __func__];
	NSLog(@"%@", err);
	@throw err;
	return nil;
}

- (id)initWithContext:(ZMQContext *)context_ type:(ZMQSocketType)type_ {
	self = [super init];
	if (!self) return nil;

	socket = zmq_socket(context_.context, type_);
	if (!socket) {
		ZMQLogError(self, @"zmq_socket");
		return nil;
	}

	context = context_;
	type = type_;
	return self;
}

@synthesize socket;
@synthesize closed;
- (void)close {
	if (!self.closed) {
		int err = zmq_close(self.socket);
		if (err) {
			ZMQLogError(self, @"zmq_close");
			return;
		}
		self.closed = YES;
	}
}


@synthesize context;
@synthesize type;
- (NSString *)description {
	NSString *typeName = [[self class] nameForSocketType:self.type];
	NSString *
	desc = [NSString stringWithFormat:
			@"<%@: %p (ctx=%p, type=%@, endpoint=%@, closed=%d)>",
			[self class], self, self.context, typeName, self.endpoint,
			(int)self.closed];
	return desc;
}

#pragma mark Socket Options
- (BOOL)setData:(NSData *)data forOption:(ZMQSocketOption)option {
	int err = zmq_setsockopt(self.socket, option, [data bytes], [data length]);
	if (err) {
		ZMQLogError(self, @"zmq_setsockopt");
		return NO;
	}
	return YES;
}

- (NSData *)dataForOption:(ZMQSocketOption)option {
	size_t length = ZMQ_SOCKET_OPTION_MAX_LENGTH;
	void *storage = malloc(length);
	if (!storage) return nil;

	int err = zmq_getsockopt(self.socket, option, storage, &length);
	if (err) {
		ZMQLogError(self, @"zmq_getsockopt");
		free(storage);
		return nil;
	}

	NSData *
	data = [NSData dataWithBytesNoCopy:storage length:length freeWhenDone:YES];
	return data;
}

#pragma mark Endpoint Configuration
@synthesize endpoint;
- (BOOL)bindToEndpoint:(NSString *)endpoint_ {
	[self setEndpoint:endpoint_];
	const char *addr = [endpoint_ UTF8String];
	int err = zmq_bind(self.socket, addr);
	if (err) {
		ZMQLogError(self, @"zmq_bind");
		return NO;
	}
	return YES;
}

- (BOOL)connectToEndpoint:(NSString *)endpoint_ {
	[self setEndpoint:endpoint_];
	const char *addr = [endpoint_ UTF8String];
	int err = zmq_connect(self.socket, addr);
	if (err) {
		ZMQLogError(self, @"zmq_connect");
		return NO;
	}
	return YES;	
}

#pragma mark Communication
- (BOOL)send:(NSData *)messageData withFlags:(ZMQMessageSendFlags)flags {
	zmq_msg_t msg;
	int err = zmq_msg_init_size(&msg, [messageData length]);
	if (err) {
		ZMQLogError(self, @"zmq_msg_init_size");
		return NO;
	}

	[messageData getBytes:zmq_msg_data(&msg) length:zmq_msg_size(&msg)];

	err = zmq_send(self.socket, &msg, flags);
	BOOL didSendData = (0 == err);
	if (!didSendData) {
		ZMQLogError(self, @"zmq_send");
		/* fall through */
	}

	err = zmq_msg_close(&msg);
	if (err) {
		ZMQLogError(self, @"zmq_msg_close");
		/* fall through */
	}
	return didSendData;
}

#pragma mark Communication
- (BOOL)send:(NSData *)messageData  {
    return [self send:messageData withFlags:0];
}


#pragma mark Communication
- (NSData*) recv:(ZMQMessageReceiveFlags) flags {
    zmq_msg_t data;
    int err = zmq_msg_init(&data);
    if (err) {
        ZMQLogError(self, @"zmq_msg_init");
        return nil;
    }
    
    errno = 0;
    err = zmq_recv(self.socket, &data, flags);
    if (err) {
        if (flags == ZMQ_NOBLOCK && errno == EAGAIN) {
            zmq_msg_close(&data);
            return nil;
        } else {
            ZMQLogError(self, @"zmq_recv");
            err = zmq_msg_close(&data);
            if (err) {
                ZMQLogError(self, @"zmq_msg_close");
            }
        }
    }
    
    size_t length = zmq_msg_size(&data);
    
    NSData* msg = [NSData dataWithBytes:zmq_msg_data(&data) length:length];
    //NSString* msg = [[NSString alloc] initWithBytes:zmq_msg_data(&data) length:length encoding:NSUTF8StringEncoding];
        
    err = zmq_msg_close(&data);
    if (err) {
        ZMQLogError(self, @"zmq_msg_close");
        /* fall through */
    }
    return msg;
}

#pragma mark Communication
- (NSData*) recv {
    return [self recv:0];
}

#pragma mark Polling
- (void)getPollItem:(zmq_pollitem_t *)outItem forEvents:(short)events {
	NSParameterAssert(NULL != outItem);

	outItem->socket = self.socket;
	outItem->events = events;
	outItem->revents = 0;
}
@end

void
ZMQLogError(id object, NSString *msg) {
	NSLog(@"%s: *** %@: %@: %s",
	      __func__, object, msg, zmq_strerror(zmq_errno()));
}
