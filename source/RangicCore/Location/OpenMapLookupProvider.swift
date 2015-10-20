//
//  Radish
//

import Foundation

import Alamofire

public class OpenMapLookupProvider: LookupProvider
{
    static private let useFake = false
    static private let fakeJson = "{\"place_id\":\"23990896\",\"licence\":\"Data \\u00a9 OpenStreetMap contributors, ODbL 1.0. http://www.openstreetmap.org/copyright\",\"osm_type\":\"node\",\"osm_id\":\"2327716570\",\"lat\":\"47.6114432\",\"lon\":\"-122.3492363\",\"display_name\":\"2225, Alaskan Way, Belltown, Seattle, King County, Washington, 98121, United States of America\",\"address\":{\"house_number\":\"2225\",\"road\":\"Alaskan Way\",\"suburb\":\"Belltown\",\"city\":\"Seattle\",\"county\":\"King County\",\"state\":\"Washington\",\"postcode\":\"98121\",\"country\":\"United States of America\",\"country_code\":\"us\"}}"
    static private let fakeData = fakeJson.dataUsingEncoding(NSUTF8StringEncoding)
    static public var BaseLocationLookup = "http://open.mapquestapi.com"
    static public let DefaultLocationLookup = "http://open.mapquestapi.com"
    static public var timeoutInSeconds: Double = 5.0

    public init()
    {
    }

    /// Synchronously resolves latitude/longitude into a dictionary of component names. "DisplayName" is a single string while the rest of
    /// the items are address details, ordered from most detailed to least detailed
    public func lookup(latitude: Double, longitude: Double) -> OrderedDictionary<String,String>
    {
        let mutex = Mutex()

        Logger.debug("OpenMap lookup: \(latitude), \(longitude)")
        var result: OrderedDictionary<String,String>? = nil

        if OpenMapLookupProvider.useFake {
            fakeLookup(latitude, longitude: longitude, completion: { (placename: OrderedDictionary<String,String>) -> () in
                result = placename
                mutex.signal()
            })
        }
        else {
            asyncLookup(latitude, longitude: longitude, completion: { (placename: OrderedDictionary<String,String>) -> () in
                result = placename
                mutex.signal()
            })
        }

        mutex.wait()
        return result!
    }

    private func fakeLookup(latitude: Double, longitude: Double, completion: (placename: OrderedDictionary<String,String>) -> ())
    {
        completion(placename: OpenMapLookupProvider.responseDataToDictionary(OpenMapLookupProvider.fakeData))
    }

    private func asyncLookup(latitude: Double, longitude: Double, completion: (placename: OrderedDictionary<String,String>) -> ())
    {
        if OpenMapLookupProvider.BaseLocationLookup.characters.count == 0 {
            OpenMapLookupProvider.BaseLocationLookup = OpenMapLookupProvider.DefaultLocationLookup
        }

        if OpenMapLookupProvider.BaseLocationLookup == OpenMapLookupProvider.DefaultLocationLookup {
            Logger.info("Looking up via \(OpenMapLookupProvider.BaseLocationLookup): \(latitude), \(longitude)")
        }

//        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
//        configuration.timeoutIntervalForRequest = OpenMapLookupProvider.timeoutInSeconds
//        configuration.timeoutIntervalForResource = OpenMapLookupProvider.timeoutInSeconds
//        let manager = Alamofire.Manager(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let manager = Alamofire.Manager.sharedInstance

        manager.request(
            .GET,
            "\(OpenMapLookupProvider.BaseLocationLookup)/nominatim/v1/reverse",
            parameters: [
                "key": "Uw7GOgmBu6TY9KGcTNoqJWO7Y5J6JSxg",
                "format": "json",
                "addressdetails": "1",
                "zoom": "18",
                "accept-language": "en-us",
                "lat": "\(latitude)",
                "lon": "\(longitude)"])
            .validate()
            .response { _, response, data, error in

                if error != nil {
                    completion(placename: self.errorToDictionary(response, data: data, error: error))
                }
                else {
                    completion(placename: OpenMapLookupProvider.responseDataToDictionary(data))
                }
        }
    }

    private func errorToDictionary(response: NSHTTPURLResponse?, data: NSData?, error: ErrorType?) -> OrderedDictionary<String,String>
    {
        let message = NSString(data:data!, encoding:NSUTF8StringEncoding) as! String
        if error != nil {
            Logger.error("reverse geocode failed with error: \(error!._code) - \(error!._domain)")

            var result = OrderedDictionary<String,String>()
            result["apiStatusCode"] = String(error!._code)
            result["apiMessage"] = error!._domain
            return result
        }
        else if response != nil {
            Logger.error("reverse geocode failed with code: \(response!.statusCode), '\(message)'")

            var result = OrderedDictionary<String,String>()
            result["apiStatusCode"] = String(response!.statusCode)
            result["apiMessage"] = message
            return result
        }
        else {
            Logger.error("reverse geocode failed with unknown error")

            var result = OrderedDictionary<String,String>()
            result["apiMessage"] = "reverse geocode failed with unknown error"
            return result

        }
    }

    static public func dictionaryToResponse(dictionary: OrderedDictionary<String,String>) -> String
    {
        var response = [String:AnyObject]()
        var address = [String:AnyObject]()

        for (key, value) in dictionary.values {
            switch key {
                case "DisplayName":
                    response["display_name"] = value
                case "apiStatusCode", "apiMessage", "geoError":
                    response[key] = value
            default:
                address[key] = value
            }
        }

        if address.count > 0 {
            response["address"] = address
        }

        return JSON(response).rawString(NSUTF8StringEncoding, options:NSJSONWritingOptions(rawValue: 0))!
    }

    static public func responseDataToDictionary(data: NSData?) -> OrderedDictionary<String,String>
    {
        var result = OrderedDictionary<String,String>()

        let json = JSON(data:NSData(data: data!))
        if let geoError = json["error"].string {
            Logger.error("reverse geocode failed with message: '\(geoError)'")
            result["geoError"] = geoError
        }
        else {
            let displayName = json["display_name"].string
            if displayName != nil {
                result["DisplayName"] = displayName
            }

            // Placenames are best & most easily represented when the address is ordered from most detailed to least detailed
            // We cheat by using the display name values to match the address components properly
            if let address = json["address"].dictionary {

                if displayName != nil {

                    for detailValue in (displayName?.componentsSeparatedByString(","))! {
                        let trimmedValue = detailValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                        var matched = false
                        for (key, value) in address {
                            if value.stringValue == trimmedValue {
                                result[key] = value.stringValue
                                matched = true
                                break
                            }
                        }

                        if !matched {
                            Logger.warn("Failed matching detail value: '\(trimmedValue)' (\(address))")
                        }
                    }
                }
                else {
                    for (key, value) in address {
                        result[key] = value.stringValue
                    }
                }
            }
        }

        return result
    }
}