//
//

open class FileMediaData : MediaData
{
    open static func create(_ url: URL, mediaType: SupportedMediaTypes.MediaType) -> FileMediaData
    {
        let fileMediaData = FileMediaData()
        fileMediaData.url = url
        fileMediaData.type = mediaType

        fileMediaData.reload()

        return fileMediaData
    }

    open override func reload()
    {
        var values: URLResourceValues
        try! values = url.resourceValues(forKeys: [URLResourceKey.contentModificationDateKey])
        let fileTimestamp = values.contentModificationDate
        
        name = url.lastPathComponent
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
            if let videoMetadata = VideoMetadata(filename: url.path) {
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
        for detail in FileExifProvider.getDetails(url.path) {
            base.append(detail)
        }
        return base
    }

    open override func doesExist() -> Bool
    {
        return FileManager.default.fileExists(atPath: url.path)
    }

    open override func setFileDateToExifDate() -> (succeeded:Bool, errorMessage:String)
    {
        let updatedDates:[FileAttributeKey:Any] = [FileAttributeKey.creationDate:timestamp as AnyObject, FileAttributeKey.modificationDate:timestamp as AnyObject]
        do {
            try FileManager.default.setAttributes(updatedDates, ofItemAtPath: url.path)

            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            let date = attrs[FileAttributeKey.creationDate] as! Date?
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

    fileprivate override init()
    {
        super.init()
    }
}
