//
//

import Alamofire
import SwiftyJSON


open class FindAPhotoResults
{
    static public let DefaultMediaDataProperties = "city,createdDate,id,imageName,keywords,latitude,longitude,mediaType,mediaURL,path,signature,thumbURL"


    public var hasError = false
    public var errorMessage:String?
    public var totalMatches:Int?


    public var items = [FindAPhotoMediaData]()

    private var host: String
    private var searchText: String
    private var properties: String
    private var first:Int
    private var count:Int


    
    public static func search(_ host: String, text: String, first: Int, count: Int, completion: @escaping (_ results: FindAPhotoResults) -> ())
    {
        let results = FindAPhotoResults(host: host, searchText: text)
        results.search(first: first, count: count, properties: FindAPhotoResults.DefaultMediaDataProperties, completion: completion)
    }
    
    // Don't make a call to the server - return the item if it's present locally
    open func getLocalItem(_ index: Int) -> MediaData?
    {
        if index >= first && index < first + items.count {
            return items[index - first]
        }
        return nil
    }

    open func itemAtIndex(index: Int, completion: @escaping(_ mediaData: MediaData?) -> ())
    {
        if let mediaData = getLocalItem(index) {
            completion(mediaData)
        } else {
            // The index isn't in our items, do another search
            self.search(first: index, count: self.count, properties: self.properties, completion: { (result: FindAPhotoResults) -> () in
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
        self.count = 0
        self.properties = FindAPhotoResults.DefaultMediaDataProperties
    }

    private func search(first: Int, count: Int, properties: String, completion: @escaping (_ results: FindAPhotoResults) -> ())
    {
        Logger.debug("FindAPhoto search: \(host) - '\(searchText)', first: \(first), count: \(count)")
        self.properties = properties

        if host.last != "/" {
            host.append("/")
        }

        let url = "\(host)api/search"
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
                    self.count = count
                    self.handleData(response.data)
                }

                completion(self)
        }
    }

    func handleError(_ url: String, response: HTTPURLResponse?, data: Data?, error: Error?)
    {
        hasError = true
        let message = NSString(data:data!, encoding:String.Encoding.utf8.rawValue)! as String
        if error != nil {
            errorMessage = "\(url): \(error!._code) - \(error!._domain); \(error!.localizedDescription)"
        }
        else if response != nil {
            errorMessage = "\(url): \(response!.statusCode), '\(message)'"
        }
        else {
            errorMessage = "\(url): Unknown error: \(message)"
        }
    }

    func handleData(_ data: Data?)
    {
        do {
            let json = try JSON(data:NSData(data: data!) as Data)
            totalMatches = json["totalMatches"].int
            items = [FindAPhotoMediaData]()
            
            // If there are any matches, then there are one or more groups, each with one or more items
            for group in json["groups"].arrayValue {
                for item in group["items"].arrayValue {
                    items.append(FindAPhotoMediaData.create(item, host: host))
                }
            }
        } catch {
            // Eat the exception...
        }
    }
}
