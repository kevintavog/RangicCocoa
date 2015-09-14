//
//  RangicFsEventStreamWrapper
//

#import "RangicFsEventStreamWrapper.h"


static void RangicFSEventStreamWrapperCallback(ConstFSEventStreamRef streamRef,
                                                void *clientCallBackInfo,
                                                size_t numEvents,
                                                void *eventPaths,
                                                const FSEventStreamEventFlags eventFlags[],
                                                const FSEventStreamEventId eventIds[]);


@implementation RangicFsEventStreamWrapper
{
    FSEventStreamRef _stream;
    RangicFsEventStreamWrapperCallback _callback;
}

- (instancetype)initWithPath:(NSString *)pathToWatch callback:(RangicFsEventStreamWrapperCallback)callback
{
    NSAssert(callback != nil, @"Parameter 'callback' cannot be 'nil'");
    NSAssert([pathToWatch isKindOfClass:[NSString class]], @"Parameter 'pathToWatch' must be an NSString");


    self = [super init];
    if (self) {
        FSEventStreamContext context = {0};
        context.info = (__bridge void*)self;
        context.copyDescription = NULL;
        context.release = NULL;
        context.retain = NULL;
        context.version = 0;


        NSArray* pathArray = [NSArray arrayWithObject:pathToWatch];

        _stream = FSEventStreamCreate(kCFAllocatorDefault,
                                      &RangicFSEventStreamWrapperCallback,
                                      &context,
                                      (__bridge CFArrayRef)pathArray,
                                      kFSEventStreamEventIdSinceNow,
                                      0.2,
                                      kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents);
        _callback = callback;

        if (_stream == nil) {
            @throw [NSException exceptionWithName:@"RangicFsEventStreamWrapper" reason:@"Could not create 'FSEventStreamRef'" userInfo:nil];
        }

        FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        FSEventStreamStart(_stream);
    }
    return self;
}

- (void)dealloc
{
    FSEventStreamStop(_stream);
    FSEventStreamInvalidate(_stream);
    FSEventStreamRelease(_stream);
}

- (RangicFsEventType) typeFromFlags:(const FSEventStreamEventFlags) flags filePath:(NSString*) filePath
{
    if (flags == kFSEventStreamEventFlagNone
        || (flags & kFSEventStreamEventFlagMustScanSubDirs) != 0
        || (flags & kFSEventStreamEventFlagUserDropped) != 0
        || (flags & kFSEventStreamEventFlagKernelDropped) != 0) {
        return RescanFolder;
    }
    else if ((flags & kFSEventStreamEventFlagItemCreated) != 0) {
        return Created;
    }
    else if ((flags & kFSEventStreamEventFlagItemRemoved) != 0) {
        return Removed;
    }
    else if ((flags & kFSEventStreamEventFlagItemRenamed) != 0) {
        // If it exists, this path is the new name. Otherwise, it's the removed name
        if ([[NSFileManager defaultManager] fileExistsAtPath: filePath]) {
            return Created;
        }
        else {
            return Removed;
        }
    }
    else if ((flags & kFSEventStreamEventFlagItemInodeMetaMod) != 0
             || (flags & kFSEventStreamEventFlagItemModified) != 0) {
        return Updated;
    }
    else {
        NSLog(@"RangicFsEventStreamWrapper ???: 0x%08X", flags);
        return RescanFolder;
    }
}

- (void) processEvents:(size_t)numEvents eventPaths:(void *)eventPaths eventFlags:(const FSEventStreamEventFlags[])eventFlags
{
    NSArray *pathArray = (__bridge NSArray*)eventPaths;
    RangicFsEventType rangicTypes[numEvents];

    for (int index = 0; index < numEvents; ++index) {
        NSString* path = [pathArray objectAtIndex:index];
        rangicTypes[index] = [self typeFromFlags: eventFlags[index] filePath: path];

//        NSLog(@"0x%08X - %ld - %@", eventFlags[index], (long)type, path);

    }

    _callback((int) numEvents, rangicTypes, pathArray);
}


@end



static void RangicFSEventStreamWrapperCallback(ConstFSEventStreamRef streamRef,
                                               void *clientCallBackInfo,
                                               size_t numEvents,
                                               void *eventPaths,
                                               const FSEventStreamEventFlags eventFlags[],
                                               const FSEventStreamEventId eventIds[])
{
    RangicFsEventStreamWrapper*	wrapper = (__bridge RangicFsEventStreamWrapper*)clientCallBackInfo;
    [wrapper processEvents:numEvents eventPaths:eventPaths eventFlags:eventFlags];
}

