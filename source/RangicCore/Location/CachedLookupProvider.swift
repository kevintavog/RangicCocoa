//
//

import Foundation

public class CachedLookupProvider: LookupProvider
{
    static var cache = Dictionary<String, OrderedDictionary<String,String>>()
    let innerLookupProvider: LookupProvider = OpenMapLookupProvider()

    /// Asynchronously resolves latitude/longitude into a dictionary of component names. "DisplayName" is a single string
    public func lookup(latitude: Double, longitude: Double) -> OrderedDictionary<String,String>
    {
        let key = Location.toDms(latitude, longitude: longitude)
        if let result = CachedLookupProvider.cache[key] {
            return result
        }
        else {
            let result = innerLookupProvider.lookup(latitude, longitude: longitude)
            CachedLookupProvider.cache[key] = result
            return result
        }
    }

}