//
//  Radish
//

import Foundation

public class MediaProvider
{
    public var mediaFiles:[MediaData] = []

    var folders:[String] = []
    var folderWatcher:[RangicFsEventStreamWrapper] = []

    public init()
    {
    }

    public func setFileDatesToExifDates(files: [MediaData]) -> (allSucceeded:Bool, failedFiles:[MediaData], errorMessage: String)
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

        CoreNotifications.postNotification(CoreNotifications.MediaProvider.UpdatedNotification, object: self)
        return response
    }

    public func clear()
    {
        folders = []
        mediaFiles = []
        folderWatcher = []

        CoreNotifications.postNotification(CoreNotifications.MediaProvider.Cleared, object: self)
    }

    public func addFolder(folderName:String)
    {
        addFolder(folderName, notifyOnLoad:true)
    }

    private func addFolder(folderName:String, notifyOnLoad:Bool)
    {
        if (folders.contains(folderName)) {
            return
        }

        if NSFileManager.defaultManager().fileExistsAtPath(folderName) {
            if let files = getFiles(folderName) {
                folders.append(folderName)

                for f in files {
                    let mediaType = SupportedMediaTypes.getTypeFromFileExtension(((f.path!) as NSString).pathExtension)
                    if mediaType == SupportedMediaTypes.MediaType.Image || mediaType == SupportedMediaTypes.MediaType.Video {
                        mediaFiles.append(FileMediaData.create(f, mediaType: mediaType))
                    }
                }
            }

            mediaFiles.sortInPlace( { (m1:MediaData, m2:MediaData) -> Bool in
                return m1.timestamp!.compare(m2.timestamp!) == NSComparisonResult.OrderedAscending })

            CoreNotifications.postNotification(CoreNotifications.MediaProvider.UpdatedNotification, object: self)

            folderWatcher.append(RangicFsEventStreamWrapper(path: folderName, callback: { (numEvents, typeArray, pathArray) -> () in
                var eventTypes = [RangicFsEventType]()
                for index in 0..<Int(numEvents) {
                    eventTypes.append(typeArray[index] as RangicFsEventType)
                }
                self.processFileSystemEvents(Int(numEvents), eventTypes: eventTypes, pathArray: pathArray as! [String])
            }))
        }
    }

    public func refresh()
    {
        let allFolders = folders
        clear()

        for f in allFolders {
            addFolder(f, notifyOnLoad: false)
        }

        CoreNotifications.postNotification(CoreNotifications.MediaProvider.UpdatedNotification, object: self)
    }

    private func processFileSystemEvents(numEvents: Int, eventTypes: [RangicFsEventType], pathArray: [String])
    {
        for index in 0..<numEvents {
            processOneFileSystemEvent(eventTypes[index], path: pathArray[index])
        }

        CoreNotifications.postNotification(CoreNotifications.MediaProvider.UpdatedNotification, object: self)
    }

    private func processOneFileSystemEvent(eventType: RangicFsEventType, path: String)
    {
        if eventType == .RescanFolder {
            rescanFolder(path)
        }
        else {
            let mediaType = SupportedMediaTypes.getTypeFromFileExtension((path as NSString).pathExtension)
            if mediaType == .Unknown {
                return
            }

            let url = NSURL(fileURLWithPath: path)
            if eventType == .Removed {
                removeFile(url)
            }
            else {
                switch eventType {
                case .Created:
                    addFile(url, mediaType: mediaType)

                case .Updated:
                    updateFile(url, mediaType: mediaType)

                case .Removed:
                    break

                case .RescanFolder:
                    break
                }
            }
        }
    }

    private func rescanFolder(path: String)
    {
        Logger.info("RescanFolder: \(path)")
    }

    private func addFile(url: NSURL, mediaType: SupportedMediaTypes.MediaType)
    {
        if let index = getFileIndex(url) {
            mediaFiles[index].reload()
        } else {
            let mediaData = FileMediaData.create(url, mediaType: mediaType)
            let index = getMediaDataIndex(mediaData)
            if index < 0 {
                mediaFiles.insert(mediaData, atIndex: -index)
            }
            else {
                mediaFiles.removeAtIndex(index)
                mediaFiles.insert(mediaData, atIndex: index)
            }
        }
    }

    private func removeFile(url: NSURL)
    {
        if let index = getFileIndex(url) {
            mediaFiles.removeAtIndex(index)
        }
        else {
            Logger.warn("Unable to remove '\(url)' - cannot find in media files")
        }
    }

    private func updateFile(url: NSURL, mediaType: SupportedMediaTypes.MediaType)
    {
        if let index = getFileIndex(url) {
            mediaFiles[index].reload()
        }
        else {
            Logger.info("Updated file '\(url)' not in list, adding it")
            addFile(url, mediaType: mediaType)
            mediaFiles.sortInPlace(isOrderedBefore)
        }
    }

    public func getFileIndex(url: NSURL) -> Int?
    {
        for (index, mediaData) in mediaFiles.enumerate() {
            if mediaData.url == url {
                return index
            }
        }

        return nil
    }

    public func itemFromFilePath(filePath: String) -> MediaData?
    {
        for mediaData in mediaFiles {
            if let urlPath = mediaData.url.path {
                if urlPath == filePath {
                    return mediaData
                }
            }
        }
        return nil
    }

    private func getMediaDataIndex(mediaData: MediaData) -> Int
    {
        var lo = 0
        var hi = mediaFiles.count - 1
        while lo <= hi {
            let mid = (lo + hi) / 2

            let midPath = mediaFiles[mid].url.path!
            if midPath.compare(mediaData.url.path!, options: NSStringCompareOptions.CaseInsensitiveSearch) == NSComparisonResult.OrderedSame {
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

    private func isOrderedBefore(m1: MediaData, m2: MediaData) -> Bool
    {
        let dateComparison = m1.timestamp!.compare(m2.timestamp!)
        switch dateComparison {
        case .OrderedAscending:
            return true
        case .OrderedDescending:
            return false
        case .OrderedSame:
            switch m1.name.compare(m2.name) {
            case .OrderedAscending:
                return true
            case .OrderedDescending:
                return false
            case .OrderedSame:
                return true
            }
        }
    }

    private func getFiles(folderName:String) -> [NSURL]?
    {
        do {
            return try NSFileManager.defaultManager().contentsOfDirectoryAtURL(
                NSURL(fileURLWithPath: folderName),
                includingPropertiesForKeys: [NSURLContentModificationDateKey],
                options:NSDirectoryEnumerationOptions.SkipsHiddenFiles)
        }
        catch {
            return nil
        }
    }
}