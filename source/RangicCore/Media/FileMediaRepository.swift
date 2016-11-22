//
//

open class FileMediaRepository : MediaRepository
{
    fileprivate var mediaFiles:[MediaData] = []
    
    var folders:[String] = []
    var folderWatcher:[RangicFsEventStreamWrapper] = []

    public init() {
    }
    

    open var mediaCount: Int { get { return mediaFiles.count } }

    open func enumerated() -> EnumeratedSequence<Array<MediaData>> {
        return mediaFiles.enumerated()
    }

    open func itemAtIndex(index: Int, completion: @escaping(_ mediaData: MediaData?) -> ()) {
        completion(getMedia(index))
    }

    open func getMedia(_ index: Int) -> MediaData? {
        return mediaFiles[index]
    }

    open func clear() {
        folders = []
        mediaFiles = []
        folderWatcher = []
    }

    open func refresh() {
        let allFolders = folders
        clear()
        
        for f in allFolders {
            addFolder(f, notifyOnLoad: false)
        }
    }
    
    open func addFolder(_ folderName:String, notifyOnLoad:Bool)
    {
        if (folders.contains(folderName)) {
            return
        }
        
        if FileManager.default.fileExists(atPath: folderName) {
            if let files = getFiles(folderName) {
                folders.append(folderName)
                
                for f in files {
                    let mediaType = SupportedMediaTypes.getTypeFromFileExtension(((f.path) as NSString).pathExtension)
                    if mediaType == SupportedMediaTypes.MediaType.image || mediaType == SupportedMediaTypes.MediaType.video {
                        mediaFiles.append(FileMediaData.create(f, mediaType: mediaType))
                    }
                }
            }
            
            mediaFiles.sort( by: { (m1:MediaData, m2:MediaData) -> Bool in
                return m1.timestamp!.compare(m2.timestamp! as Date) == ComparisonResult.orderedAscending })
            
            sendNotification(MediaProvider.Notifications.UpdatedNotification)
            
            folderWatcher.append(RangicFsEventStreamWrapper(path: folderName, callback: { (numEvents, typeArray, pathArray) -> () in
                var eventTypes = [RangicFsEventType]()
                for index in 0..<Int(numEvents) {
                    eventTypes.append((typeArray?[index])! as RangicFsEventType)
                }
                self.processFileSystemEvents(Int(numEvents), eventTypes: eventTypes, pathArray: pathArray as! [String])
            }))
        }
    }

    open func setFileDatesToExifDates(_ files: [MediaData]) -> (allSucceeded:Bool, failedFiles:[MediaData], errorMessage: String)
    {
        var response = (allSucceeded: true, failedFiles: [MediaData](), errorMessage: "")

        for mf in files {
            let result = mf.setFileDateToExifDate()
            if !result.succeeded {
                
                response.allSucceeded = false
                response.failedFiles.append(mf)
                
                if response.errorMessage.characters.count < 1 {
                    response.errorMessage = result.errorMessage
                }
            }
        }

        return response
    }

    open func getFileIndex(_ url: URL) -> Int?
    {
        for (index, mediaData) in mediaFiles.enumerated() {
            if mediaData.url == url {
                return index
            }
        }
        
        return nil
    }
    
    open func itemFromFilePath(_ filePath: String) -> MediaData?
    {
        for mediaData in mediaFiles {
            let urlPath = mediaData.url.path
            if urlPath == filePath {
                return mediaData
            }
        }
        return nil
    }

    //---------------------------
    func sendNotification(_ notification: String)
    {
        CoreNotifications.postNotification(notification, object: nil)
    }

    fileprivate func processFileSystemEvents(_ numEvents: Int, eventTypes: [RangicFsEventType], pathArray: [String])
    {
        for index in 0..<numEvents {
            processOneFileSystemEvent(eventTypes[index], path: pathArray[index])
        }
        
        sendNotification(MediaProvider.Notifications.UpdatedNotification)
    }
    
    fileprivate func processOneFileSystemEvent(_ eventType: RangicFsEventType, path: String)
    {
        if eventType == .RescanFolder {
            // Ignore
        }
        else {
            let mediaType = SupportedMediaTypes.getTypeFromFileExtension((path as NSString).pathExtension)
            if mediaType == .unknown {
                return
            }
            
            let url = URL(fileURLWithPath: path)
            if eventType == .Removed {
                removeFile(url)
            }
            else {
                let fileExists = FileManager.default.fileExists(atPath: url.path)
                switch eventType {
                case .Created:
                    if fileExists {
                        addFile(url, mediaType: mediaType)
                    }
                    
                case .Updated:
                    if fileExists {
                        updateFile(url, mediaType: mediaType)
                    }
                    
                case .Removed:
                    break
                    
                case .RescanFolder:
                    break
                }
            }
        }
    }
    
    fileprivate func addFile(_ url: URL, mediaType: SupportedMediaTypes.MediaType)
    {
        if let index = getFileIndex(url) {
            mediaFiles[index].reload()
        } else {
            let mediaData = FileMediaData.create(url, mediaType: mediaType)
            let index = getMediaDataIndex(mediaData)
            if index < 0 {
                mediaFiles.insert(mediaData, at: -index)
            }
            else {
                mediaFiles.remove(at: index)
                mediaFiles.insert(mediaData, at: index)
            }
        }
    }
    
    fileprivate func removeFile(_ url: URL)
    {
        if let index = getFileIndex(url) {
            mediaFiles.remove(at: index)
        }
        else {
            Logger.warn("Unable to remove '\(url)' - cannot find in media files")
        }
    }
    
    fileprivate func updateFile(_ url: URL, mediaType: SupportedMediaTypes.MediaType)
    {
        if let index = getFileIndex(url) {
            mediaFiles[index].reload()
        }
        else {
            Logger.info("Updated file '\(url)' not in list, adding it")
            addFile(url, mediaType: mediaType)
            mediaFiles.sort(by: isOrderedBefore)
        }
    }
    
    fileprivate func getMediaDataIndex(_ mediaData: MediaData) -> Int
    {
        var lo = 0
        var hi = mediaFiles.count - 1
        while lo <= hi {
            let mid = (lo + hi) / 2
            
            let midPath = mediaFiles[mid].url.path
            if midPath.compare(mediaData.url.path, options: NSString.CompareOptions.caseInsensitive) == ComparisonResult.orderedSame {
                return mid
            }
            
            if isOrderedBefore(mediaFiles[mid], m2:mediaData) {
                lo = mid + 1
            } else if isOrderedBefore(mediaData, m2:mediaFiles[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return -lo // not found, would be inserted at position lo
    }
    
    fileprivate func isOrderedBefore(_ m1: MediaData, m2: MediaData) -> Bool
    {
        let dateComparison = m1.timestamp!.compare(m2.timestamp! as Date)
        switch dateComparison {
        case .orderedAscending:
            return true
        case .orderedDescending:
            return false
        case .orderedSame:
            switch m1.name.compare(m2.name) {
            case .orderedAscending:
                return true
            case .orderedDescending:
                return false
            case .orderedSame:
                return true
            }
        }
    }
    
    fileprivate func getFiles(_ folderName:String) -> [URL]?
    {
        do {
            return try FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: folderName),
                includingPropertiesForKeys: [URLResourceKey.contentModificationDateKey],
                options:FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
        }
        catch {
            return nil
        }
    }
}
