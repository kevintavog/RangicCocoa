//
//  Radish
//

import Foundation

import Alamofire
import SwiftyJSON

open class OpenMapLookupProvider: LookupProvider
{
    static fileprivate let useFake = false
    static fileprivate let fakeJson = "{\"place_id\":\"23990896\",\"licence\":\"Data \\u00a9 OpenStreetMap contributors, ODbL 1.0. http://www.openstreetmap.org/copyright\",\"osm_type\":\"node\",\"osm_id\":\"2327716570\",\"lat\":\"47.6114432\",\"lon\":\"-122.3492363\",\"display_name\":\"2225, Alaskan Way, Belltown, Seattle, King County, Washington, 98121, United States of America\",\"address\":{\"house_number\":\"2225\",\"road\":\"Alaskan Way\",\"suburb\":\"Belltown\",\"city\":\"Seattle\",\"county\":\"King County\",\"state\":\"Washington\",\"postcode\":\"98121\",\"country\":\"United States of America\",\"country_code\":\"us\"}}"
    static fileprivate let fakeData = fakeJson.data(using: String.Encoding.utf8)
    static open var BaseLocationLookup = "http://open.mapquestapi.com"
    static open let DefaultLocationLookup = "http://open.mapquestapi.com"
    static open var timeoutInSeconds: Double = 5.0

    public init()
    {
    }

    /// Synchronously resolves latitude/longitude into a dictionary of component names. "DisplayName" is a single string while the rest of
    /// the items are address details, ordered from most detailed to least detailed
    open func lookup(_ latitude: Double, longitude: Double) -> OrderedDictionary<String,String>
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

    fileprivate func fakeLookup(_ latitude: Double, longitude: Double, completion: (_ placename: OrderedDictionary<String,String>) -> ())
    {
        completion(OpenMapLookupProvider.responseDataToDictionary(OpenMapLookupProvider.fakeData))
    }

    fileprivate func asyncLookup(_ latitude: Double, longitude: Double, completion: @escaping (_ placename: OrderedDictionary<String,String>) -> ())
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

        let url = "\(OpenMapLookupProvider.BaseLocationLookup)/nominatim/v1/reverse"
        Alamofire.request(
            url,
            parameters: [
                "key": "Uw7GOgmBu6TY9KGcTNoqJWO7Y5J6JSxg",
                "format": "json",
                "addressdetails": "1",
                "zoom": "18",
                "accept-language": "en-us",
                "lat": "\(latitude)",
                "lon": "\(longitude)"])
            .validate()
            .response { response in

                if response.error != nil {
                    completion(self.errorToDictionary(url, response: response.response, data: response.data, error: response.error))
                }
                else {
                    completion(OpenMapLookupProvider.responseDataToDictionary(response.data))
                }
        }
    }

    fileprivate func errorToDictionary(_ url: String, response: HTTPURLResponse?, data: Data?, error: Error?) -> OrderedDictionary<String,String>
//    fileprivate func errorToDictionary(_ url: String, response: HTTPURLResponse?, data: Data?, error: Error?) -> OrderedDictionary<String,String>
    {
        let message = NSString(data:data!, encoding:String.Encoding.utf8.rawValue) as! String
        if error != nil {
            Logger.error("reverse geocode to (\(url)) failed with error: \(error!._code) - \(error!._domain)")

            var result = OrderedDictionary<String,String>()
            result["apiStatusCode"] = String(error!._code)
            result["apiMessage"] = error!._domain
            return result
        }
        else if response != nil {
            Logger.error("reverse geocode to (\(url)) failed with code: \(response!.statusCode), '\(message)'")

            var result = OrderedDictionary<String,String>()
            result["apiStatusCode"] = String(response!.statusCode)
            result["apiMessage"] = message
            return result
        }
        else {
            Logger.error("reverse geocode to (\(url)) failed with unknown error")

            var result = OrderedDictionary<String,String>()
            result["apiMessage"] = "reverse geocode failed with unknown error"
            return result

        }
    }

    static open func dictionaryToResponse(_ dictionary: OrderedDictionary<String,String>) -> String
    {
        var response = [String:AnyObject]()
        var address = [String:AnyObject]()

        for (key, value) in dictionary.values {
            switch key {
                case "DisplayName":
                    response["display_name"] = value as AnyObject?
                case "apiStatusCode", "apiMessage", "geoError":
                    response[key] = value as AnyObject?
            default:
                address[key] = value as AnyObject?
            }
        }

        if address.count > 0 {
            response["address"] = address as AnyObject?
        }

        return JSON(response).rawString(String.Encoding.utf8, options:JSONSerialization.WritingOptions(rawValue: 0))!
    }

    static open func responseDataToDictionary(_ data: Data?) -> OrderedDictionary<String,String>
    {
        var result = OrderedDictionary<String,String>()

        let json = JSON(data:NSData(data: data!) as Data)
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

                    for detailValue in (displayName?.components(separatedBy: ","))! {
                        let trimmedValue = detailValue.trimmingCharacters(in: CharacterSet.whitespaces)
                        var matched = false
                        for (key, value) in address {
                            if value.stringValue == trimmedValue {
                                result[key] = value.stringValue
                                matched = true
                                break
                            }
                        }

//                        if !matched {
//                            Logger.verbose("Failed matching detail value: '\(trimmedValue)' (\(address))")
//                        }
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
