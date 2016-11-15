//
//  Radish
//

import Foundation
import Async

open class MediaData
{
    open var name: String!
    open var url: URL!
    open var timestamp: Date!
    open var fileTimestamp: Date!
    open var location: Location!
    open var type: SupportedMediaTypes.MediaType!
    open var keywords: [String]!
    open var mediaSize: MediaSize?
    open var rotation: Int?
    open var compatibleBrands: [String]!


    static fileprivate var dateFormatter: DateFormatter? = nil
    fileprivate var cachedDetails: [MediaDataDetail]!


    open var details: [MediaDataDetail]!
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

    open func doesExist() -> Bool
    {
        return true
    }

    open func doFileAndExifTimestampsMatch() -> Bool
    {
        return timestamp == fileTimestamp
    }

    open func locationString() -> String
    {
        if let l = location {
            return "\(l.toDms())"
        }
        else {
            return ""
        }
    }

    open var nameWithoutExtension: String { return NSString(string: name!).deletingPathExtension }

    open func keywordsString() -> String
    {
        if let k = keywords {
            return k.joined(separator: ", ")
        }
        else {
            return ""
        }
    }

    open func formattedTime() -> String
    {
        if MediaData.dateFormatter == nil {
            MediaData.dateFormatter = DateFormatter()
            MediaData.dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }

        return MediaData.dateFormatter!.string(from: timestamp!)
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

    open func setFileDateToExifDate() -> (succeeded:Bool, errorMessage:String)
    {
        return (false, "Not implemented")
    }

    open func reload()
    {
        cachedDetails = nil
        Logger.error("reload not supported by MediaData derivative")
    }
}
