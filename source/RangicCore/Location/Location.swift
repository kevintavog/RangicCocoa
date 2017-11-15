//
//  Radish
//

import Foundation

open class Location : Hashable
{
    open fileprivate(set) var latitude: Double
    open fileprivate(set)  var longitude: Double
    fileprivate var placename: Placename?
    static fileprivate let lookupProvider: LookupProvider = MemoryCacheLookupProvider()


    public init(latitude:Double, longitude:Double)
    {
        self.latitude = latitude
        self.longitude = longitude
        self.placename = nil
    }

    public init(latitude:Double, latitudeReference:String, longitude:Double, longitudeReference:String)
    {
        if latitudeReference == "S" {
            self.latitude = latitude * -1.0
        }
        else {
            self.latitude = latitude
        }

        if longitudeReference == "W" {
            self.longitude = longitude * -1.0
        }
        else {
            self.longitude = longitude
        }
    }

    open var description: String
    {
        return toDms()
    }

    open func toDms() -> String
    {
        return Location.toDms(latitude, longitude: longitude)
    }

    open func metersFrom(_ location: Location) -> Double
    {
        return Location.metersBetween(self, location2: location)
    }

    static open func metersBetween(_ location1: Location, location2: Location) -> Double
    {
        let lat1rad = location1.latitude * Double.pi/180
        let lon1rad = location1.longitude * Double.pi/180
        let lat2rad = location2.latitude * Double.pi/180
        let lon2rad = location2.longitude * Double.pi/180

        let dLat = lat2rad - lat1rad
        let dLon = lon2rad - lon1rad
        let a = sin(dLat/2) * sin(dLat/2) + sin(dLon/2) * sin(dLon/2) * cos(lat1rad) * cos(lat2rad)
        let c = 2 * asin(sqrt(a))
        let R = 6372.8
        
        return (R * c) * 1000.0
    }

    static open func toDms(_ latitude: Double, longitude: Double) -> String
    {
        let latitudeNorthOrSouth = latitude < 0 ? "S" : "N"
        let longitudeEastOrWest = longitude < 0 ? "W" : "E"
        return "\(toDms(latitude)) \(latitudeNorthOrSouth), \(toDms(longitude)) \(longitudeEastOrWest)"
    }

    static fileprivate func toDms(_ geo: Double) -> String
    {
        var g = geo
        if (g < 0.0) {
            g *= -1.0
        }

        let degrees = Int(g)
        let minutesDouble = (g - Double(degrees)) * 60.0
        let minutesInt = Int(minutesDouble)
        let seconds = (minutesDouble - Double(minutesInt)) * 60.0

        return String(format: "%.2d° %.2d' %.2f\"", degrees, minutesInt, seconds)
    }

    open func toDecimalDegrees(_ humanReadable: Bool) -> String
    {
        if humanReadable {
            return NSString(format: "%.6f, %.6f", latitude, longitude) as String
        }

        return "\(latitude), \(longitude)"
    }

    open func placenameAsString(_ filter: PlaceNameFilter = .detailed) -> String
    {
        if !hasPlacename() {
            self.placename = Placename(components: Location.lookupProvider.lookup(latitude, longitude: longitude))
        }

        return (placename?.name(filter))!
    }

    open func asPlacename() -> Placename?
    {
        if !hasPlacename() {
            self.placename = Placename(components: Location.lookupProvider.lookup(latitude, longitude: longitude))
        }
        return placename
    }

    open func hasPlacename() -> Bool
    {
        return placename != nil
    }

    open var hashValue: Int { get { return 17 &* latitude.hashValue &* longitude.hashValue } }
}

public func ==(lhs: Location, rhs: Location) -> Bool
{
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}
