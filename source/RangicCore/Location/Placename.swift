//
//

import SwiftyJSON

open class Placename
{
    public let description: String
    public let fullDescription: String
    public let site: String?
    public let city: String?
    public let state: String?
    public let countryCode: String?
    public let countryName: String?

    public init() {
        self.description = ""
        self.fullDescription = ""
        self.site = nil
        self.city = nil
        self.state = nil
        self.countryCode = nil
        self.countryName = nil
    }

    public init(json: JSON)
    {
        self.site = json["site"].string
        self.city = json["city"].string
        self.state = json["state"].string
        self.countryName = json["countryName"].string
        self.countryCode = json["countryCode"].string
        self.fullDescription = json["fullDescription"].stringValue

        let nameComponents = [
            site,
            city,
            state,
            countryName]
        self.description = nameComponents.flatMap( { $0 }).joined(separator: ", ")
}

    open func name(_ filter: PlaceNameFilter, countryFirst: Bool = false) -> String
    {
        switch filter {
            case .none:
                return fullDescription

            case .minimal:
                return description

            case .standard:
                return description

            case .detailed:
                return fullDescription
        }
    }

}

public enum PlaceNameFilter
{
    case none, minimal, standard, detailed
}
