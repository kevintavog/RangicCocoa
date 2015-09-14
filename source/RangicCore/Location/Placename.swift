//
//

public class Placename
{
    public let components: OrderedDictionary<String,String>

    public init(components: OrderedDictionary<String,String>)
    {
        self.components = components
    }

    public func name(filter: PlaceNameFilter, countryFirst: Bool = false) -> String
    {
        var parts = [String]()

        if filter == .Standard {
            let siteName = getFirstMatch(Placename.prioritizedSiteComponent)
            let city = getFirstMatch(Placename.prioritizedCityNameComponent)
            if siteName != nil {
                parts.append(siteName)
            }
            if city != nil {
                parts.append(city)
            }
        }

        for key in components.keys {
            let value = components[key]!
            switch filter {
            case .None:
                if key != "DisplayName" {
                    parts.append(value)
                }

            case .Minimal:
                if key != "country_code" {
                    if key == "county" {
                        if !components.keys.contains("city") {
                            parts.append(value)
                        }
                    }
                    else {
                        parts.append(value)
                    }
                }

            case .Standard:
                if Placename.acceptedStandardComponents.contains(key) {
                    parts.append(value)
                }

            case .Detailed:
                if Placename.acceptedDetailedComponents.contains(key) {
                    parts.append(value)
                }
            }
        }

        if parts.count == 0 && parts.contains("DisplayName") {
            parts.append(components["DisplayName"]!)
        }

        if countryFirst {
            parts = parts.reverse()
        }

        return parts.joinWithSeparator(", ")
    }

    private func getFirstMatch(prioritizedList: [String]) -> String!
    {
        for key in prioritizedList {
            if let value = components[key] {
                return value
            }
        }
        return nil
    }

    private func isExcluded(key: String, value: String) -> Bool
    {
        if let excludedValues = Placename.fieldExclusions[key] {
            return excludedValues.contains(value)
        }
        return false
    }


    private static let acceptedStandardComponents: Set<String> =
    [
        "state",
        "country"
    ]

    private static let acceptedDetailedComponents: Set<String> =
    [
        "state",
        "country",


        // City/county details
        "city",
        "city_district",    // Perhaps shortest of this & city?
        "town",
        "hamlet",
        "locality",
        "neighbourhood",
        "suburb",
        "village",
        "county",


        // Site details
        "playground",

        "aerodrome",
        "archaeological_site",
        "arts_centre",
        "attraction",
        "bakery",
        "bar",
        "basin",
        "building",
        "cafe",
        "car_wash",
        "chemist",
        "cinema",
        "cycleway",
        "department_store",
        "fast_food",
        "furniture",
        "garden",
        "garden_centre",
        "golf_course",
        "grave_yard",
        "hospital",
        "hotel",
        "house",
        "information",
        "library",
        "mall",
        "marina",
        "memorial",
        "military",
        "monument",
        "motel",
        "museum",
        "park",
        "parking",
        "path",
        "pedestrian",
        "pitch",
        "place_of_worship",
        "pub",
        "public_building",
        "restaurant",
        "roman_road",
        "school",
        "slipway",
        "sports_centre",
        "stadium",
        "supermarket",
        "theatre",
        "townhall",
        "viewpoint",
        "water",
        "zoo",

        "footway",
        "nature_reserve"
    ]

    // For 'cityname'
    private static let prioritizedCityNameComponent: [String] =
    [
        "city",
        "city_district",    // Perhaps shortest of this & city?
        "town",
        "hamlet",
        "locality",
        "neighbourhood",
        "suburb",
        "village",
        "county"
    ]

    // For the point of interest / site / building
    private static let prioritizedSiteComponent: [String] =
    [
        "playground",

        "aerodrome",
        "archaeological_site",
        "arts_centre",
        "attraction",
        "bakery",
        "bar",
        "basin",
        "building",
        "cafe",
        "car_wash",
        "chemist",
        "cinema",
        "cycleway",
        "department_store",
        "fast_food",
        "furniture",
        "garden",
        "garden_centre",
        "golf_course",
        "grave_yard",
        "hospital",
        "hotel",
        "house",
        "information",
        "library",
        "mall",
        "marina",
        "memorial",
        "military",
        "monument",
        "motel",
        "museum",
        "park",
        "parking",
        "path",
        "pedestrian",
        "pitch",
        "place_of_worship",
        "pub",
        "public_building",
        "restaurant",
        "roman_road",
        "school",
        "slipway",
        "sports_centre",
        "stadium",
        "supermarket",
        "theatre",
        "townhall",
        "viewpoint",
        "water",
        "zoo",

        "footway",
        "nature_reserve"
    ]

    static private let fieldExclusions: [String: Set<String>] =
    [
        "country" : [ "United States of America", "United Kingdom" ]
    ]

}

public enum PlaceNameFilter
{
    case None, Minimal, Standard, Detailed
}
