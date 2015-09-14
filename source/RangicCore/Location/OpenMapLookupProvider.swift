//
//  Radish
//

import Foundation

import Alamofire

public class OpenMapLookupProvider: LookupProvider
{
    /// Synchronously resolves latitude/longitude into a dictionary of component names. "DisplayName" is a single string while the rest of
    /// the items are address details, ordered from most detailed to least detailed
    public func lookup(latitude: Double, longitude: Double) -> OrderedDictionary<String,String>
    {
        let mutex = Mutex()

        var result: OrderedDictionary<String,String>? = nil

        asyncLookup(latitude, longitude: longitude, completion: { (placename: OrderedDictionary<String,String>) -> () in
            result = placename
            mutex.signal()
        })

        mutex.wait()
        return result!
    }

    private func asyncLookup(latitude: Double, longitude: Double, completion: (placename: OrderedDictionary<String,String>) -> ())
    {
        var result = OrderedDictionary<String,String>()
        Alamofire.request(
            .GET,
            "http://open.mapquestapi.com/nominatim/v1/reverse",
            parameters: ["format": "json", "addressdetails": "1", "zoom": "18", "accept-language": "en-us", "lat": "\(latitude)", "lon": "\(longitude)"])
            .validate()
            .response { _, response, data, error in

                if error != nil {
                    let message = NSString(data:data!, encoding:NSUTF8StringEncoding) as! String
                    Logger.log("reverse geocode failed with code: \(response?.statusCode), '\(message)'")
                }
                else {
                    let json = JSON(data:NSData(data: data!))
                    if let geoError = json["error"].string {
                        Logger.log("reverse geocode failed with message: '\(geoError)'")
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
                                        Logger.log("Failed matching detail value: '\(trimmedValue)' (\(address))")
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
                }
                
                completion(placename: result)
        }

    }
}