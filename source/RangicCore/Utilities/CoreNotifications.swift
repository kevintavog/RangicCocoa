//
//  RangicCore
//

import Foundation

open class CoreNotifications
{
    open class MediaProvider
    {
        static open let Cleared = "MediaProvider.Cleared"
        static open let UpdatedNotification = "MediaProvider.UpdatedNotification"
        static open let DetailsAvailable = "MediaProvider.DetailsAvailable"
    }

    static open func postNotification(_ notification: String, object: AnyObject? = nil, userInfo: [AnyHashable: Any]? = nil)
    {
        NotificationCenter.default.post(name: Notification.Name(rawValue: notification), object: object, userInfo: userInfo)
    }

    static open func addObserver(_ observer: AnyObject, selector: Selector, name: String, object: AnyObject?)
    {
        NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: name), object: object)
    }

    static open func removeObserver(_ observer: AnyObject, name: String, object: AnyObject?)
    {
        NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: name), object: object)
    }

    static open func removeObserver(_ observer: AnyObject, object: AnyObject?)
    {
        NotificationCenter.default.removeObserver(observer, name: nil, object: object)
    }
}
