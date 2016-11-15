//
//  RangicCore
//

import Foundation

public struct Mutex
{
    fileprivate let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

    public init()
    {
    }

    public func signal()
    {
        semaphore.signal()
    }

    public func wait()
    {
        let _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
}
