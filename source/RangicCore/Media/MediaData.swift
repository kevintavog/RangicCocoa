//
//  Radish
//

import Foundation
import Async

public enum ImageOrientation : Int
{
    case topLeft = 1,
        topRight = 2,
        bottomRight = 3,
        bottomLeft = 4,
        leftTop = 5,
        rightTop = 6,
        rightBottom = 7,
        leftBottom = 8
}

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
    open var durationSeconds: Double = 0.0

    open var mediaSignature: String {
        get {
            if !signaturePopulated {
                cachedMediaSignature = getMediaSignature()
                signaturePopulated = true
            }
            return cachedMediaSignature!
        }
    }

    open var thumbUrl: URL { get { return url! } }


    static fileprivate var dateFormatter: DateFormatter? = nil
    static fileprivate var timeFormatter: DateFormatter? = nil
    fileprivate var cachedDetails: [MediaDataDetail]!
    fileprivate var signaturePopulated = false
    fileprivate var cachedMediaSignature: String?

    open var parentPath: String
    {
        let pathComponents = (url!.path as NSString).pathComponents
        return pathComponents.count >= 2 ? pathComponents[pathComponents.count - 2] : ""
    }

    open var details: [MediaDataDetail]!
    {
        get {
            if cachedDetails == nil {
                Async.background {
                    self.cachedDetails = self.loadDetails()
                    CoreNotifications.postNotification(MediaProvider.Notifications.DetailsAvailable, object: self, userInfo: nil)
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

    open func formattedDate() -> String
    {
        if MediaData.dateFormatter == nil {
            MediaData.dateFormatter = DateFormatter()
            MediaData.dateFormatter!.dateFormat = "yyyy-MM-dd"
        }
        
        return MediaData.dateFormatter!.string(from: timestamp!)
    }
    
    open func formattedTime() -> String
    {
        if MediaData.timeFormatter == nil {
            MediaData.timeFormatter = DateFormatter()
            MediaData.timeFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }

        return MediaData.timeFormatter!.string(from: timestamp!)
    }

    internal func loadDetails() -> [MediaDataDetail]
    {
        var details = [MediaDataDetail]()

        if let l = location {
            if let pn = l.asPlacename() {
                
                details.append(MediaDataDetail(category: "Placename", name: nil, value: nil))
                if let sites = pn.sites {
                    details.append(MediaDataDetail(category: nil, name: "sites", value: sites.joined(separator: ", ")))
                }
                details.append(MediaDataDetail(category: nil, name: "city", value: pn.city))
                details.append(MediaDataDetail(category: nil, name: "state", value: pn.state))
                details.append(MediaDataDetail(category: nil, name: "country", value: pn.countryName))
                details.append(MediaDataDetail(category: nil, name: "countryCode", value: pn.countryCode))
                details.append(MediaDataDetail(category: nil, name: "description", value: pn.description))
                details.append(MediaDataDetail(category: nil, name: "fullDescription", value: pn.fullDescription))
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
    
    func getMediaSignature() -> String
    {
        Logger.error("Your subclass must implement 'getMediaSignature'")
        return "Your subclass must implement 'getMediaSignature'"
    }
}
