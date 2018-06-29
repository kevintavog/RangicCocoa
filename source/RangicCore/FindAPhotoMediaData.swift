//
//

import SwiftyJSON

open class FindAPhotoMediaData : MediaData
{
    fileprivate var signature:String?
    fileprivate var path:String?
    fileprivate var mediaThumbUrl:URL?
    
    static var dateFormatter: DateFormatter? = nil
    static func getDateFormatter() -> DateFormatter
    {
        if dateFormatter == nil {
            dateFormatter = DateFormatter()
            dateFormatter?.dateFormat = "yyyy-MM-dd'T'HH:mm:ssX"
        }
        return dateFormatter!
    }

    open static func create(_ json:JSON, host: String) -> FindAPhotoMediaData
    {
        var normalizedHost = host
        if normalizedHost.last == "/" {
            normalizedHost = String(normalizedHost[...normalizedHost.index(before: normalizedHost.endIndex)])
        }

        let fpMediaData = FindAPhotoMediaData()

        // Hack - assume all media is rotated properly. It speeds up loading due to using NSImage versus CGImage, essentially
        fpMediaData.rotation = 1

        fpMediaData.name = json["imageName"].stringValue
        fpMediaData.url = URL(string: normalizedHost.appending(json["mediaURL"].stringValue))
        fpMediaData.timestamp = getDateFormatter().date(from: json["createdDate"].stringValue)
        fpMediaData.fileTimestamp = fpMediaData.timestamp
        fpMediaData.keywords = json["keywords"].arrayObject as! [String]?
        fpMediaData.path = json["path"].stringValue
        fpMediaData.signature = json["signature"].string
        fpMediaData.mediaThumbUrl = URL(string: normalizedHost.appending(json["thumbURL"].stringValue))

        if json["latitude"].exists() && json["longitude"].exists() {
            fpMediaData.location = Location(latitude: json["latitude"].doubleValue, longitude: json["longitude"].doubleValue)
        }

        switch json["mediaType"].stringValue {
        case "image":
            fpMediaData.type = SupportedMediaTypes.MediaType.image
        case "video":
            fpMediaData.type = SupportedMediaTypes.MediaType.video
        default:
            Logger.warn("Unknown FindAPhoto media type: \(json["mediatype"].stringValue)")
        }


//        open var mediaSize: MediaSize?
//        open var rotation: Int?
//        open var compatibleBrands: [String]!
        
        
        return fpMediaData
    }

    override open var parentPath: String
    {
        let pathComponents = (self.path!.replacingOccurrences(of: "\\", with: "/") as NSString).pathComponents
        return pathComponents.count >= 2 ? pathComponents[pathComponents.count - 2] : ""
    }

    override func getMediaSignature() -> String
    {
        return signature!
    }

    override open var thumbUrl: URL { get { return mediaThumbUrl! } }

    fileprivate override init()
    {
        super.init()
    }
}
