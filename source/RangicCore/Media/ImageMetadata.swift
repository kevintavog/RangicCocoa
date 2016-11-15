//
//  RangicCore
//

open class ImageMetadata
{
    static fileprivate var dateFormatter: DateFormatter?

    open var timestamp: Date? = nil
    open var location: Location? = nil
    open var keywords: [String]? = nil
    open var mediaSize: MediaSize? = nil


    public init?(url: URL)
    {
        if (ImageMetadata.dateFormatter == nil)
        {
            ImageMetadata.dateFormatter = DateFormatter()
            ImageMetadata.dateFormatter!.dateFormat = "yyyy:MM:dd HH:mm:ss"
        }


        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)
        {
            if let rawProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)
            {
                let properties = rawProperties as Dictionary

                if let imageWidth = properties[kCGImagePropertyPixelWidth],
                    let imageHeight = properties[kCGImagePropertyPixelHeight] {
                        let width = imageWidth as? Int
                        let height = imageHeight as? Int
                        mediaSize = MediaSize(width: width!, height: height!)
                }

                // EXIF timestamp (Exif.DateTimeOriginal)
                if let exifProperties = properties[kCGImagePropertyExifDictionary]
                {
                    if let dateTimeOriginal = exifProperties.value(forKey: kCGImagePropertyExifDateTimeOriginal as String)
                    {
                        timestamp = ImageMetadata.dateFormatter!.date(from: dateTimeOriginal as! String)
                    }
                    else if let dateTimeDigitized = exifProperties.value(forKey: kCGImagePropertyExifDateTimeDigitized as String)
                    {
                        timestamp = ImageMetadata.dateFormatter!.date(from: dateTimeDigitized as! String)
                    }
                    else
                    {
                        if let tiffProperties = properties[kCGImagePropertyTIFFDictionary]
                        {
                            if let dateTime = tiffProperties.value(forKey: kCGImagePropertyTIFFDateTime as String)
                            {
                                timestamp = ImageMetadata.dateFormatter!.date(from: dateTime as! String)
                            }
                        }
                    }
                }

                // keywords (IPTC.Keywords)
                if let iptcProperties = properties[kCGImagePropertyIPTCDictionary]
                {
                    if let iptcKeywords = iptcProperties.value(forKey: kCGImagePropertyIPTCKeywords as String)
                    {
                        keywords = iptcKeywords as? [String]
                    }
                }

                // location (GPS.Latitude, LatitudeRef, Longitude, LongitudeRef)
                if let gpsProperties = properties[kCGImagePropertyGPSDictionary]
                {
                    if let latitude = gpsProperties.value(forKey: kCGImagePropertyGPSLatitude as String),
                        let latitudeRef = gpsProperties.value(forKey: kCGImagePropertyGPSLatitudeRef as String),
                        let longitude = gpsProperties.value(forKey: kCGImagePropertyGPSLongitude as String),
                        let longitudeRef = gpsProperties.value(forKey: kCGImagePropertyGPSLongitudeRef as String)
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
