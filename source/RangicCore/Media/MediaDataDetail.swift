//
//  Radish
//

open class MediaDataDetail
{
    open let category: String?
    open let name: String?
    open let value: String?

    init(category: String?, name: String?, value: String?)
    {
        self.category = category
        self.name = name
        self.value = value
    }
}
