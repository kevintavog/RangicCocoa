//
//

public class FileMediaData : MediaData
{
    public static func create(url: NSURL, mediaType: SupportedMediaTypes.MediaType) -> FileMediaData
    {
        let fileMediaData = FileMediaData()
        fileMediaData.url = url
        fileMediaData.type = mediaType

        fileMediaData.reload()

        return fileMediaData
    }

    public override func reload()
    {
        var value:AnyObject?
        try! url.getResourceValue(&value, forKey: NSURLContentModificationDateKey)
        let fileTimestamp = value as! NSDate?

        name = url.lastPathComponent!
        timestamp = fileTimestamp
        self.fileTimestamp = fileTimestamp
        compatibleBrands = [String]()

        var hasImageData = false
        if let imageMetadata = ImageMetadata(url: url) {
            hasImageData = true
            if let timestamp = imageMetadata.timestamp {
                self.timestamp = timestamp
            }
            keywords = imageMetadata.keywords
            location = imageMetadata.location
            mediaSize = imageMetadata.mediaSize
        }

        if !hasImageData {
            if let videoMetadata = VideoMetadata(filename: url.path!) {
                if let timestamp = videoMetadata.timestamp {
                    self.timestamp = timestamp
                }
                location = videoMetadata.location
                keywords = videoMetadata.keywords
                mediaSize = videoMetadata.mediaSize
                rotation = videoMetadata.rotation
                compatibleBrands = videoMetadata.compatibleBrands
            }
        }
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

    public override func setFileDateToExifDate() -> (succeeded:Bool, errorMessage:String)
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