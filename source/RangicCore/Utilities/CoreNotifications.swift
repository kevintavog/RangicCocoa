//
//  Radish
//

import Foundation

public class CoreNotifications
{
    public class MediaProvider
    {
        static public let Cleared = "MediaProvider.Cleared"
        static public let UpdatedNotification = "MediaProvider.UpdatedNotification"
        static public let DetailsAvailable = "MediaProvider.DetailsAvailable"
    }

    static public func postNotification(notification: String, object: AnyObject? = nil, userInfo: [NSObject : AnyObject]? = nil)
    {
        NSNotificationCenter.defaultCenter().postNotificationName(notification, object: object, userInfo: userInfo)
    }

    static public func addObserver(observer: AnyObject, selector: Selector, name: String, object: AnyObject?)
    {
        NSNotificationCenter.defaultCenter().addObserver(observer, selector: selector, name: name, object: object)
    }

    static public func removeObserver(observer: AnyObject, name: String, object: AnyObject?)
    {
        NSNotificationCenter.defaultCenter().removeObserver(observer, name: name, object: object)
    }

    static public func removeObserver(observer: AnyObject, object: AnyObject?)
    {
        NSNotificationCenter.defaultCenter().removeObserver(observer, name: nil, object: object)
    }
}