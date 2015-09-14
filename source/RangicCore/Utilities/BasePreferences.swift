//
//  RangicCore
//

import Foundation

public class BasePreferences
{
    // I'd prefer these set* & *ForKey funcs be accessible only to derived classes...


    // Doubles
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

    // Floats
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


    static public func keyExists(key: String) -> Bool
    {
        return NSUserDefaults.standardUserDefaults().objectForKey(key) != nil
    }

}