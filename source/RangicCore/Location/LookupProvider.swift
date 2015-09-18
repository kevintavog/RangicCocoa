//
//

import Foundation

public protocol LookupProvider
{
    // Resolves lat/long to a placename, each component is a field in the returned dictionary. Note that
    // "DisplayName" is a single item containing the full placename
    func lookup(latitude: Double, longitude: Double) -> OrderedDictionary<String,String>
}