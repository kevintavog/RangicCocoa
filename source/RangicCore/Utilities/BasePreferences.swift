//
//  RangicCore
//

open class BasePreferences
{
    // I'd prefer these set* & *ForKey funcs be accessible only to derived classes...


    // MARK: Doubles
    static open func setValue(_ value: Double, key: String)
    {
        UserDefaults.standard.set(value, forKey: key)
    }

    static open func doubleForKey(_ key: String) -> Double
    {
        return UserDefaults.standard.double(forKey: key)
    }

    static open func setDefaultValue(_ value: Double, key: String)
    {
        if (!keyExists(key)) { setValue(value, key: key) }
    }

    // MARK: Floats
    static open func setValue(_ value: Float, key: String)
    {
        UserDefaults.standard.set(value, forKey: key)
    }

    static open func floatForKey(_ key: String) -> Float
    {
        return UserDefaults.standard.float(forKey: key)
    }

    static open func setDefaultValue(_ value: Float, key: String)
    {
        if (!keyExists(key)) { setValue(value, key: key) }
    }

    // MARK: Strings
    static open func setValue(_ value: String, key: String)
    {
        UserDefaults.standard.set(value, forKey: key)
    }

    static open func stringForKey(_ key: String) -> String
    {
        if let obj = UserDefaults.standard.object(forKey: key) {
            if let str = obj as? NSString {
                return str as String
            }
        }
        return ""
    }

    static open func setDefaultValue(_ value: String, key: String)
    {
        if (!keyExists(key)) { setValue(value, key: key) }
    }

    // MARK: Ints
    static open func setValue(_ value: Int, key: String)
    {
        UserDefaults.standard.set(value, forKey: key)
    }

    static open func intForKey(_ key: String) -> Int
    {
        return UserDefaults.standard.integer(forKey: key)
    }

    static open func setDefaultValue(_ value: Int, key: String)
    {
        if (!keyExists(key)) { setValue(value, key: key) }
    }
    

    // MARK: Helpers
    static open func keyExists(_ key: String) -> Bool
    {
        return UserDefaults.standard.object(forKey: key) != nil
    }

}
