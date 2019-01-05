//
//

open class MemoryCacheLookupProvider: LookupProvider
{
    static fileprivate var cache = Dictionary<String, Placename>()
    static fileprivate let innerLookupProvider: LookupProvider = ReverseNameLookupProvider()

    open func lookup(latitude: Double, longitude: Double) -> Placename
    {
        objc_sync_enter(self)
        let key = Location.toDms(latitude, longitude: longitude)
        if let result = MemoryCacheLookupProvider.cache[key] {
            if result.description.count > 0 {
                objc_sync_exit(self)
                return result
            }
        }
        objc_sync_exit(self)

        let result = MemoryCacheLookupProvider.innerLookupProvider.lookup(latitude: latitude, longitude: longitude)

        objc_sync_enter(self)
        MemoryCacheLookupProvider.cache[key] = result
        objc_sync_exit(self)
        return result
    }
}
