//
//  Radish
//

import Foundation
import Async

public class MediaData
{
    public var name: String!
    public var url: NSURL!
    public var timestamp: NSDate!
    public var fileTimestamp: NSDate!
    public var location: Location!
    public var type: SupportedMediaTypes.MediaType!
    public var keywords: [String]!
    public var mediaSize: MediaSize?


    static private var dateFormatter: NSDateFormatter? = nil
    private var cachedDetails: [MediaDataDetail]!


    public var details: [MediaDataDetail]!
    {
        get {
            if cachedDetails == nil {
                Async.background {
                    self.cachedDetails = self.loadDetails()
                    CoreNotifications.postNotification(CoreNotifications.MediaProvider.DetailsAvailable, object: self, userInfo: nil)
                }
                return [MediaDataDetail]()
            }
            return cachedDetails
        }
    }

    public func doesExist() -> Bool
    {
        return true
    }

    public func doFileAndExifTimestampsMatch() -> Bool
    {
        return timestamp == fileTimestamp
    }

    public func locationString() -> String
    {
        if let l = location {
            return "\(l.toDms())"
        }
        else {
            return ""
        }
    }

    public func keywordsString() -> String
    {
        if let k = keywords {
            return k.joinWithSeparator(", ")
        }
        else {
            return ""
        }
    }

    public func formattedTime() -> String
    {
        if MediaData.dateFormatter == nil {
            MediaData.dateFormatter = NSDateFormatter()
            MediaData.dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }

        return MediaData.dateFormatter!.stringFromDate(timestamp!)
    }

    internal func loadDetails() -> [MediaDataDetail]
    {
        var details = [MediaDataDetail]()

        if let l = location {
            if let components = l.asPlacename()?.components {
                details.append(MediaDataDetail(category: "Placename", name: nil, value: nil))
                for key in components.keys {
                    let value = components[key]
                    details.append(MediaDataDetail(category: nil, name: key, value: value))
                }
            }
        }

        return details
    }

    public func setFileDateToExifDate() -> (succeeded:Bool, errorMessage:String)
    {
        return (false, "Not implemented")
    }

    public func reload()
    {
        cachedDetails = nil
        Logger.error("reload not supported by MediaData derivative")
    }
}
