//
//

import Foundation

open class CoreNotifications
{
    static public func postNotification(_ notification: String, object: AnyObject? = nil, userInfo: [AnyHashable: Any]? = nil)
    {
        NotificationCenter.default.post(name: Notification.Name(rawValue: notification), object: object, userInfo: userInfo)
    }

    static public func addObserver(_ observer: AnyObject, selector: Selector, name: String, object: AnyObject?)
    {
        NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: name), object: object)
    }

    static public func removeObserver(_ observer: AnyObject, name: String, object: AnyObject?)
    {
        NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: name), object: object)
    }

    static public func removeObserver(_ observer: AnyObject, object: AnyObject?)
    {
        NotificationCenter.default.removeObserver(observer, name: nil, object: object)
    }
}
