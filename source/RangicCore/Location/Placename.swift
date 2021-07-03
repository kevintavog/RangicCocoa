//
//

import SwiftyJSON

open class Placename
{
    public let description: String
    public let fullDescription: String
    public let sites: [String]?
    public let city: String?
    public let state: String?
    public let countryCode: String?
    public let countryName: String?

    public init() {
        self.description = ""
        self.fullDescription = ""
        self.sites = nil
        self.city = nil
        self.state = nil
        self.countryCode = nil
        self.countryName = nil
    }

    public init(json: JSON)
    {
        if let siteArray = json["sites"].array {
            self.sites = siteArray.map { $0.stringValue }
        } else {
            self.sites = nil
        }
        self.city = json["city"].string
        self.state = json["state"].string
        self.countryName = json["countryName"].string
        self.countryCode = json["countryCode"].string
        self.fullDescription = json["fullDescription"].stringValue

        let nameComponents = [
            sites != nil ? sites!.joined(separator: ", ") : nil,
            city,
            state,
            countryName]
        self.description = nameComponents.compactMap( { $0 }).joined(separator: ", ")
}

    open func name(_ filter: PlaceNameFilter, countryFirst: Bool = false) -> String
    {
        switch filter {
            case .none:
                return fullDescription

            case .minimal:
                return description
            
            case .city:
                let nameComponents = [
                    city,
                    state,
                    countryName]
                return nameComponents.compactMap( { $0 }).joined(separator: ", ")

            case .cityNoCountry:
                let nameComponents = [
                    city,
                    state]
                return nameComponents.compactMap( { $0 }).joined(separator: ", ")

            case .sites:
                let nameComponents = [
                    sites != nil ? sites!.joined(separator: ", ") : nil,
                    city,
                    state,
                    countryName
                ]
                return nameComponents.compactMap( { $0} ).joined(separator: ", ")

            case .sitesNoCountry:
                let nameComponents = [
                    sites != nil ? sites!.joined(separator: ", ") : nil,
                    city,
                    state
                ]
                return nameComponents.compactMap( { $0} ).joined(separator: ", ")

            case .standard:
                return description

            case .detailed:
                return fullDescription
        }
    }

}

public enum PlaceNameFilter
{
    case none, minimal, sites, sitesNoCountry, city, cityNoCountry, standard, detailed
}
