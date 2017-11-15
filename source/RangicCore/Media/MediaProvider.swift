//
//

import Foundation

public protocol MediaRepository
{
    var mediaCount: Int { get }
    func clear()
    func refresh()
    func itemAtIndex(index: Int, completion: @escaping(_ mediaData: MediaData?) -> ())
    func getMedia(_ index: Int) -> MediaData?
    func enumerated() -> EnumeratedSequence<Array<MediaData>>

    func addFolder(_ folderName:String, notifyOnLoad:Bool)
    func setFileDatesToExifDates(_ files: [MediaData]) -> (allSucceeded:Bool, failedFiles:[MediaData], errorMessage: String)
    func getFileIndex(_ url: URL) -> Int?
    func itemFromFilePath(_ filePath: String) -> MediaData?
}

open class MediaProvider
{
    open class Notifications
    {
        static open let Cleared = "MediaProvider.Cleared"
        static open let UpdatedNotification = "MediaProvider.UpdatedNotification"
        static open let DetailsAvailable = "MediaProvider.DetailsAvailable"
    }

    fileprivate var repository: MediaRepository = FileMediaRepository()

    public init()
    {
    }

    open func setRepository(_ repository: MediaRepository) {
        self.repository.clear()
        self.repository = repository
    }

    open func enumerated() -> EnumeratedSequence<Array<MediaData>> {
        return repository.enumerated()
    }

    open var mediaCount: Int { get { return repository.mediaCount } }

    open func itemAtIndex(index: Int, completion: @escaping(_ mediaData: MediaData?) -> ()) {
        repository.itemAtIndex(index: index, completion: completion)
    }

    open func getMedia(_ index: Int) -> MediaData? {
        return repository.getMedia(index)
    }

    open func setRepository(repository: MediaRepository) {
        self.repository = repository
    }

    open func setFileDatesToExifDates(_ files: [MediaData]) -> (allSucceeded:Bool, failedFiles:[MediaData], errorMessage: String)
    {
        let response = repository.setFileDatesToExifDates(files)
        CoreNotifications.postNotification(MediaProvider.Notifications.UpdatedNotification, object: self)
        return response
    }

    open func clear()
    {
        repository.clear()
        CoreNotifications.postNotification(MediaProvider.Notifications.Cleared, object: self)
    }

    open func addFolder(_ folderName:String)
    {
        repository.addFolder(folderName, notifyOnLoad:true)
    }


    open func refresh()
    {
        repository.refresh()
        CoreNotifications.postNotification(MediaProvider.Notifications.UpdatedNotification, object: self)
    }

    open func getFileIndex(_ url: URL) -> Int?
    {
        return repository.getFileIndex(url)
    }

    open func itemFromFilePath(_ filePath: String) -> MediaData?
    {
        return repository.itemFromFilePath(filePath)
    }

}
