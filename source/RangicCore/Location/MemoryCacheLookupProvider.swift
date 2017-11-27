//
//

open class MemoryCacheLookupProvider: LookupProvider
{
    static fileprivate var cache = Dictionary<String, Placename>()
    static fileprivate let innerLookupProvider: LookupProvider = ReverseNameLookupProvider()

    open func lookup(latitude: Double, longitude: Double) -> Placename
    {
        let key = Location.toDms(latitude, longitude: longitude)
        if let result = MemoryCacheLookupProvider.cache[key] {
            if result.description.count > 0 {
                return result
            }
        }

        let result = MemoryCacheLookupProvider.innerLookupProvider.lookup(latitude: latitude, longitude: longitude)
        MemoryCacheLookupProvider.cache[key] = result
        return result
    }
}
