//
//

import Foundation

public class FileMediaData : MediaData
{
    static private var dateFormatter: NSDateFormatter?

    public static func create(url: NSURL, mediaType: SupportedMediaTypes.MediaType) -> FileMediaData
    {
        if (dateFormatter == nil)
        {
            dateFormatter = NSDateFormatter()
            dateFormatter!.dateFormat = "yyyy:MM:dd HH:mm:ss"
        }

        var value:AnyObject?
        try! url.getResourceValue(&value, forKey: NSURLContentModificationDateKey)
        let date = value as! NSDate?

        let fileMediaData = FileMediaData()
        fileMediaData.url = url
        fileMediaData.name = url.lastPathComponent!
        fileMediaData.type = mediaType
        fileMediaData.timestamp = date
        fileMediaData.fileTimestamp = date

        let imageSource = CGImageSourceCreateWithURL(url, nil)
        if imageSource != nil
        {
            if let rawProperties = CGImageSourceCopyPropertiesAtIndex(imageSource!, 0, nil)
            {
                let properties = rawProperties as Dictionary

                // EXIF timestamp (Exif.DateTimeOriginal)
                if let exifProperties = properties[kCGImagePropertyExifDictionary]
                {
                    if let dateTimeDigitized = exifProperties.valueForKey(kCGImagePropertyExifDateTimeDigitized as String)
                    {
                        fileMediaData.timestamp = dateFormatter!.dateFromString(dateTimeDigitized as! String)
                    }
                    else if let dateTimeOriginal = exifProperties.valueForKey(kCGImagePropertyExifDateTimeOriginal as String)
                    {
                        fileMediaData.timestamp = dateFormatter!.dateFromString(dateTimeOriginal as! String)
                    }
                    else
                    {
                        if let tiffProperties = properties[kCGImagePropertyTIFFDictionary]
                        {
                            if let dateTime = tiffProperties.valueForKey(kCGImagePropertyTIFFDateTime as String)
                            {
                                fileMediaData.timestamp = dateFormatter!.dateFromString(dateTime as! String)
                            }
                        }
                    }
                }

                // keywords (IPTC.Keywords)
                if let iptcProperties = properties[kCGImagePropertyIPTCDictionary]
                {
                    if let keywords = iptcProperties.valueForKey(kCGImagePropertyIPTCKeywords as String)
                    {
                        fileMediaData.keywords = keywords as! [String]
                    }
                }

                // location (GPS.Latitude, LatitudeRef, Longitude, LongitudeRef)
                if let gpsProperties = properties[kCGImagePropertyGPSDictionary]
                {
                    if let latitude = gpsProperties.valueForKey(kCGImagePropertyGPSLatitude as String),
                        latitudeRef = gpsProperties.valueForKey(kCGImagePropertyGPSLatitudeRef as String),
                        longitude = gpsProperties.valueForKey(kCGImagePropertyGPSLongitude as String),
                        longitudeRef = gpsProperties.valueForKey(kCGImagePropertyGPSLongitudeRef as String)
                    {
                        fileMediaData.location = Location(
                            latitude: latitude as! Double,
                            latitudeReference: latitudeRef as! String,
                            longitude: longitude as! Double,
                            longitudeReference: longitudeRef as! String)
                    }
                }
            }
        }

        return fileMediaData
    }

    internal override func loadDetails() -> [MediaDataDetail]
    {
        var base = super.loadDetails()
        for detail in FileExifProvider.getDetails(url.path!) {
            base.append(detail)
        }
        return base
    }

    public override func doesExist() -> Bool
    {
        return NSFileManager.defaultManager().fileExistsAtPath(url.path!)
    }

    public override func setFileDateToExifDate()  -> (succeeded:Bool, errorMessage:String)
    {
        let updatedDates:[String:AnyObject] = [NSFileCreationDate:timestamp, NSFileModificationDate:timestamp]
        do {
            try NSFileManager.defaultManager().setAttributes(updatedDates, ofItemAtPath: url.path!)

            var value:AnyObject?
            try! url.getResourceValue(&value, forKey: NSURLContentModificationDateKey)
            let date = value as! NSDate?
            fileTimestamp = date
        }
        catch let error as NSError {
            return (false, "\(error.code) - \(error.localizedDescription)")
        }
        catch {
            return (false, "Failed setting timestamp")
        }

        return (true, "")
    }

    private override init()
    {
        super.init()
    }
}