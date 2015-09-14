//
//  Radish
//

import Foundation

public struct Mutex
{
    private let semaphore: dispatch_semaphore_t = dispatch_semaphore_create(0)

    public init()
    {
    }

    public func signal()
    {
        dispatch_semaphore_signal(semaphore)
    }

    public func wait()
    {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
}