//
//  RangicCore
//

public class ImageMetadata
{
    static private var dateFormatter: NSDateFormatter?

    public var timestamp: NSDate? = nil
    public var location: Location? = nil
    public var keywords: [String]? = nil

    public init?(url: NSURL)
    {
        if (ImageMetadata.dateFormatter == nil)
        {
            ImageMetadata.dateFormatter = NSDateFormatter()
            ImageMetadata.dateFormatter!.dateFormat = "yyyy:MM:dd HH:mm:ss"
        }


        if let imageSource = CGImageSourceCreateWithURL(url, nil)
        {
            if let rawProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)
            {
                let properties = rawProperties as Dictionary

                // EXIF timestamp (Exif.DateTimeOriginal)
                if let exifProperties = properties[kCGImagePropertyExifDictionary]
                {
                    if let dateTimeDigitized = exifProperties.valueForKey(kCGImagePropertyExifDateTimeDigitized as String)
                    {
                        timestamp = ImageMetadata.dateFormatter!.dateFromString(dateTimeDigitized as! String)
                    }
                    else if let dateTimeOriginal = exifProperties.valueForKey(kCGImagePropertyExifDateTimeOriginal as String)
                    {
                        timestamp = ImageMetadata.dateFormatter!.dateFromString(dateTimeOriginal as! String)
                    }
                    else
                    {
                        if let tiffProperties = properties[kCGImagePropertyTIFFDictionary]
                        {
                            if let dateTime = tiffProperties.valueForKey(kCGImagePropertyTIFFDateTime as String)
                            {
                                timestamp = ImageMetadata.dateFormatter!.dateFromString(dateTime as! String)
                            }
                        }
                    }
                }

                // keywords (IPTC.Keywords)
                if let iptcProperties = properties[kCGImagePropertyIPTCDictionary]
                {
                    if let iptcKeywords = iptcProperties.valueForKey(kCGImagePropertyIPTCKeywords as String)
                    {
                        keywords = iptcKeywords as? [String]
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
                        location = Location(
                            latitude: latitude as! Double,
                            latitudeReference: latitudeRef as! String,
                            longitude: longitude as! Double,
                            longitudeReference: longitudeRef as! String)
                    }
                }
                return
            }
        }

        return nil
    }
}