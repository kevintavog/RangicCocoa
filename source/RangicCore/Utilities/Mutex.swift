//
//  RangicCore
//

import Foundation

// From https://github.com/mattgallagher/CwlUtils/blob/master/Sources/CwlUtils/CwlMutex.swift

/// A more specific kind of mutex that assume an underlying primitive and unbalanced lock/trylock/unlock operators
public protocol RawMutex {
    associatedtype MutexPrimitive
    
    /// Perform work inside the mutex
    func sync<R>(execute work: () throws -> R) rethrows -> R
    func trySync<R>(execute work: () throws -> R) rethrows -> R?

    /// The raw primitive is exposed as an "unsafe" public property for faster access in some cases
    var unsafeMutex: MutexPrimitive { get set }
    
    func unbalancedLock()
    func unbalancedTryLock() -> Bool
    func unbalancedUnlock()
}

extension RawMutex {
    public func sync<R>(execute work: () throws -> R) rethrows -> R {
        unbalancedLock()
        defer { unbalancedUnlock() }
        return try work()
    }
    public func trySync<R>(execute work: () throws -> R) rethrows -> R? {
        guard unbalancedTryLock() else { return nil }
        defer { unbalancedUnlock() }
        return try work()
    }
}

// Usage:
//      let mutex = PThreadMutex()
//      mutex.sync {
//          // Do something entertaining
//      }
public final class PThreadMutex: RawMutex {
    public typealias MutexPrimitive = pthread_mutex_t
    
    // Non-recursive "PTHREAD_MUTEX_NORMAL" and recursive "PTHREAD_MUTEX_RECURSIVE" mutex types.
    public enum PThreadMutexType {
        case normal
        case recursive
    }
    
    public var unsafeMutex = pthread_mutex_t()
    
    /// Default constructs as ".Normal" or ".Recursive" on request.
    public init(type: PThreadMutexType = .normal) {
        var attr = pthread_mutexattr_t()
        guard pthread_mutexattr_init(&attr) == 0 else {
            preconditionFailure()
        }
        switch type {
        case .normal:
            pthread_mutexattr_settype(&attr, Int32(PTHREAD_MUTEX_NORMAL))
        case .recursive:
            pthread_mutexattr_settype(&attr, Int32(PTHREAD_MUTEX_RECURSIVE))
        }
        guard pthread_mutex_init(&unsafeMutex, &attr) == 0 else {
            preconditionFailure()
        }
        pthread_mutexattr_destroy(&attr)
    }
    
    deinit {
        pthread_mutex_destroy(&unsafeMutex)
    }
    
    public func unbalancedLock() {
        pthread_mutex_lock(&unsafeMutex)
    }
    
    public func unbalancedTryLock() -> Bool {
        return pthread_mutex_trylock(&unsafeMutex) == 0
    }
    
    public func unbalancedUnlock() {
        pthread_mutex_unlock(&unsafeMutex)
    }
}

