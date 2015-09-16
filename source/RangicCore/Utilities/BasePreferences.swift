//
//  RangicCore
//

public class BasePreferences
{
    // I'd prefer these set* & *ForKey funcs be accessible only to derived classes...


    // MARK: Doubles
    static public func setValue(value: Double, key: String)
    {
        NSUserDefaults.standardUserDefaults().setDouble(value, forKey: key)
    }

    static public func doubleForKey(key: String) -> Double
    {
        return NSUserDefaults.standardUserDefaults().doubleForKey(key)
    }

    static public func setDefaultValue(value: Double, key: String)
    {
        if (!keyExists(key)) { setValue(value, key: key) }
    }

    // MARK: Floats
    static public func setValue(value: Float, key: String)
    {
        NSUserDefaults.standardUserDefaults().setFloat(value, forKey: key)
    }

    static public func floatForKey(key: String) -> Float
    {
        return NSUserDefaults.standardUserDefaults().floatForKey(key)
    }

    static public func setDefaultValue(value: Float, key: String)
    {
        if (!keyExists(key)) { setValue(value, key: key) }
    }

    // MARK: Strings
    static public func setValue(value: String, key: String)
    {
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: key)
    }

    static public func stringForKey(key: String) -> String
    {
        if let obj = NSUserDefaults.standardUserDefaults().objectForKey(key) {
            if let str = obj as? NSString {
                return str as String
            }
        }
        return ""
    }

    static public func setDefaultValue(value: String, key: String)
    {
        if (!keyExists(key)) { setValue(value, key: key) }
    }


    // MARK: Helpers
    static public func keyExists(key: String) -> Bool
    {
        return NSUserDefaults.standardUserDefaults().objectForKey(key) != nil
    }

}