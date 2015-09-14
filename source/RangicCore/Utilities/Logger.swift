//
//  Radish
//

import Foundation

public class Logger
{
    private static var dateFormatter:NSDateFormatter? = nil

    
    static public func log(message:String)
    {
        let now = getDateFormatter().stringFromDate(NSDate())
        print("\(now) - \(message)")
    }

    static private func getDateFormatter() -> NSDateFormatter
    {
        if (dateFormatter == nil)
        {
            dateFormatter = NSDateFormatter()
            dateFormatter!.dateFormat = "HH:mm:ss.SSS"
        }

        return dateFormatter!
    }
}