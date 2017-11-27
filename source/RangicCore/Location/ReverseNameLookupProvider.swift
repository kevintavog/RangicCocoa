//

import Foundation

import Alamofire
import SwiftyJSON

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
        
        let url = "\(ReverseNameLookupProvider.host!)api/v1/name"
        let parameters = [
            "lat": "\(latitude)",
            "lon": "\(longitude)"]

        var error: Swift.Error? = nil
        var resultData: Data? = nil
        let semaphore = DispatchSemaphore(value: 0)
        Alamofire.request(url, parameters: parameters)
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
            return Placename(json: json)
        } catch {
            return Placename()
        }
    }
}
