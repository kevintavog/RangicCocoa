//
//  RangicFsEventStreamWrapper
//

#import <Foundation/Foundation.h>
#import	<CoreServices/CoreServices.h>


typedef NS_ENUM(NSInteger, RangicFsEventType)
{
    Created,
    Removed,
    RescanFolder,
    Updated

};

typedef void(^RangicFsEventStreamWrapperCallback)(int numEvents, const RangicFsEventType eventType[], NSArray *eventPaths);


@interface RangicFsEventStreamWrapper : NSObject

- (instancetype) initWithPath:(NSString *)pathToWatch callback:(RangicFsEventStreamWrapperCallback)callback;
- (void)dealloc;

- (void) processEvents:(size_t)numEvents eventPaths:(void *)eventPaths eventFlags:(const FSEventStreamEventFlags[])eventFlags;
- (RangicFsEventType) typeFromFlags:(const FSEventStreamEventFlags)flags filePath:(NSString*)filePath;

@end