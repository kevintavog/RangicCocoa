//
//

open class MemoryCacheLookupProvider: LookupProvider
{
    static fileprivate var cache = Dictionary<String, OrderedDictionary<String,String>>()
    static fileprivate let innerLookupProvider: LookupProvider = PersistentCacheLookupProvider()

    open func lookup(_ latitude: Double, longitude: Double) -> OrderedDictionary<String,String>
    {
        let key = Location.toDms(latitude, longitude: longitude)
        if let result = MemoryCacheLookupProvider.cache[key] {
            if result.count > 0 {
                return result
            }
        }

        let result = MemoryCacheLookupProvider.innerLookupProvider.lookup(latitude, longitude: longitude)
        MemoryCacheLookupProvider.cache[key] = result
        return result
    }
}
