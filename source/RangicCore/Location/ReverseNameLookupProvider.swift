//

import Foundation

import Alamofire
import SwiftyJSON

struct ReverseNameRequest {
    var items: [ReverseNameRequestItem]
}

struct ReverseNameRequestItem {
    var lat: Double
    var lon: Double
}

struct ReverseNameResponse {
    var items: [ReverseNameResponseItem]?
    var hasErrors: Bool?
}

struct ReverseNameResponseItem {
    var placename: ReverseNamePlacename
}

struct ReverseNamePlacename {
    var fullDescription: String?
    var sites: [String]?
    var city: String?
    var state: String?
    var countryName: String?
    var countryCode: String?
}

open class ReverseNameLookupProvider : LookupProvider {

    static var host: String?


    public static func set(host: String) {
        var tempHost = host
        if tempHost.last != "/" {
            tempHost.append("/")
        }
        self.host = tempHost
    }

    public init() {
    }

    public func lookup(latitude: Double, longitude: Double) -> Placename {

        if ReverseNameLookupProvider.host == nil {
            print("ReverseNameLookupProvider.host hasn't been set, lookups won't be attempted")
            return Placename()
        }
        
        let url = "\(ReverseNameLookupProvider.host!)names"

        let parameters: Parameters = [
            "items": [
                [
                    "lat": latitude,
                    "lon": longitude
                ]
            ]
        ]
        
        var error: Swift.Error? = nil
        var resultData: Data? = nil
        let semaphore = DispatchSemaphore(value: 0)
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .response { response in

                if response.error != nil {
                    error = response.error
                }
                else {
                    resultData = response.data
                }

                semaphore.signal()
        }

        semaphore.wait()
        if error != nil {
            return Placename()
        }

        do {
            let json = try JSON(data: resultData!)
            return Placename(json: json["items"][0]["placename"])
        } catch {
            return Placename()
        }
    }
}
