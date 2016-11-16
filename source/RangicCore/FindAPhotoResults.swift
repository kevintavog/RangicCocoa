//
//

import Alamofire
import SwiftyJSON


open class FindAPhotoResults
{
    static open let DefaultMediaDataProperties = "city,createdDate,id,imageName,keywords,latitude,longitude,mediaType,mediaURL,path,signature"


    public var hasError = false
    public var errorMessage:String?
    public var totalMatches:Int?


    private var items = [FindAPhotoMediaData]()
    private var host: String
    private var searchText: String
    private var properties: String
    private var first:Int


    
    open static func search(_ host: String, text: String, first: Int, count: Int, completion: @escaping (_ results: FindAPhotoResults) -> ())
    {
        var results = FindAPhotoResults(host: host, searchText: text)
        results.search(first: first, count: count, properties: FindAPhotoResults.DefaultMediaDataProperties, completion: completion)
    }

    open func itemAtIndex(index: Int, completion: @escaping(_ mediaData: MediaData?) -> ())
    {
        if index >= first && index <= first + items.count {
            completion(items[index - first])
        } else {
            // The index isn't in our items, do another search
            self.search(first: index, count: 1, properties: self.properties, completion: { (result: FindAPhotoResults) -> () in
                if self.hasError {
                    completion(nil)
                } else {
                    completion(self.items[0])
                }
            })
        }
    }

    private init(host: String, searchText: String)
    {
        self.host = host
        self.searchText = searchText
        self.first = -1
        self.properties = FindAPhotoResults.DefaultMediaDataProperties
    }

    private func search(first: Int, count: Int, properties: String, completion: @escaping (_ results: FindAPhotoResults) -> ())
    {
        Logger.debug("FindAPhoto search: \(host) - '\(searchText)', first: \(first), count: \(count)")
        self.properties = properties


        let url = "\(host)/api/search"
        let parameters = [
            "q": "\(searchText)",
            "first": "\(first)",
            "count": "\(count)",
            "properties": properties]

        Alamofire.request(url, parameters: parameters)
            .validate()
            .response { response in

                if response.error != nil {
                    self.handleError(url, response: response.response, data: response.data, error: response.error)
                }
                else {
                    self.first = first
                    self.handleData(response.data)
                }

                completion(self)
        }
    }

    func handleError(_ url: String, response: HTTPURLResponse?, data: Data?, error: Error?)
    {
        hasError = true
        let message = NSString(data:data!, encoding:String.Encoding.utf8.rawValue) as! String
        if error != nil {
            errorMessage = "\(error!._code) - \(error!._domain); \(error!.localizedDescription)"
        }
        else if response != nil {
            errorMessage = "\(response!.statusCode), '\(message)'"
        }
        else {
            errorMessage = "Unknown error: \(message)"
        }

        Logger.error("FindAPhoto request failed: \(errorMessage!)")
    }

    func handleData(_ data: Data?)
    {
        let json = JSON(data:NSData(data: data!) as Data)
        totalMatches = json["totalMatches"].int
        items = [FindAPhotoMediaData]()

        // If there are any matches, then there are one or more groups, each with one or more items
        for group in json["groups"].arrayValue {
            for item in group["items"].arrayValue {
                items.append(FindAPhotoMediaData.create(item, host: host))
            }
        }
    }
}