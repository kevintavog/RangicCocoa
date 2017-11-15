//
//

open class FindAPhotoMediaRepository : MediaRepository
{
    var results: FindAPhotoResults?
    var totalMatches:Int = 0

    public init() {
    }
    
    open func newSearch(host: String, searchText: String) {
        totalMatches = 0
        FindAPhotoResults.search(
            host,
            text: searchText,
            first: 1,
            count: 10,
            completion: { (result: FindAPhotoResults) -> () in
                self.results = result
                if result.hasError {
                    Logger.warn("Search returned an error: \(String(describing: result.errorMessage))")
                } else {
                    self.totalMatches = result.totalMatches!
                }

                self.sendNotification(MediaProvider.Notifications.UpdatedNotification)
        })
    }

    open var mediaCount: Int { get { return totalMatches } }

    open func enumerated() -> EnumeratedSequence<Array<MediaData>> {
        Logger.warn("FindAPhotoMediaRepository.enumerated not implemented")
        return [MediaData]().enumerated()
    }

    open func itemAtIndex(index: Int, completion: @escaping(_ mediaData: MediaData?) -> ()) {
        // FindAPhoto uses a 1-based index
        results?.itemAtIndex(index: index + 1, completion: completion)
    }

    open func getMedia(_ index: Int) -> MediaData? {
        // FindAPhoto uses a 1-based index
        return results?.getLocalItem(index + 1)
    }

    open func clear() {
    }

    open func refresh() {
    }

    open func addFolder(_ folderName:String, notifyOnLoad:Bool)
    {
        Logger.warn("FindAPhotoMediaRepository.addFolder not implemented")
        return;
    }

    open func setFileDatesToExifDates(_ files: [MediaData]) -> (allSucceeded:Bool, failedFiles:[MediaData], errorMessage: String)
    {
        Logger.warn("FindAPhotoMediaRepository.setFileDatesToExifDates not implemented")
        return (allSucceeded: true, failedFiles: [MediaData](), errorMessage: "")
    }

    open func getFileIndex(_ url: URL) -> Int?
    {
        Logger.warn("FindAPhotoMediaRepository.getFileIndex not implemented")
        return nil
    }

    open func itemFromFilePath(_ filePath: String) -> MediaData?
    {
        Logger.warn("FindAPhotoMediaRepository.itemFromFilePath not implemented")
        return nil
    }

    //---------------------------
    func sendNotification(_ notification: String)
    {
        CoreNotifications.postNotification(notification, object: self)
    }
}
