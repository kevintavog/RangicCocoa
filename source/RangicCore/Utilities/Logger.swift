//
//  RangicCore
//

import CocoaLumberjackSwift

public class Logger
{
    static public func configure()
    {
        DDTTYLogger.sharedInstance().logFormatter = RangicLogFormatter()
        DDLog.addLogger(DDTTYLogger.sharedInstance())

        let fileLogger = DDFileLogger()
        fileLogger.logFormatter = RangicLogFormatter()
        fileLogger.rollingFrequency = 24 * 60 * 60
        fileLogger.logFileManager.maximumNumberOfLogFiles = 10
        DDLog.addLogger(fileLogger)
    }

    static public func error(message:String)
    {
        DDLogError("\(message)")
    }

    static public func warn(message:String)
    {
        DDLogWarn("\(message)")
    }

    static public func info(message:String)
    {
        DDLogInfo("\(message)")
    }

    static public func debug(message:String)
    {
        DDLogDebug("\(message)")
    }

    static public func verbose(message:String)
    {
        DDLogVerbose("\(message)")
    }
}

public class RangicLogFormatter : NSObject, DDLogFormatter
{
    static let calUnits = NSCalendarUnit(rawValue:
        NSCalendarUnit.Year.rawValue
            | NSCalendarUnit.Month.rawValue
            | NSCalendarUnit.Day.rawValue
            | NSCalendarUnit.Hour.rawValue
            | NSCalendarUnit.Minute.rawValue
            | NSCalendarUnit.Second.rawValue)

    static var _cachedAppName: String?
    static var appName: String
    {
        if _cachedAppName == nil {
            _cachedAppName = NSProcessInfo.processInfo().processName
        }
        return _cachedAppName!
    }

    @objc public func formatLogMessage(logMessage: DDLogMessage) -> String
    {
        var level = "<none>"
        if logMessage.flag.contains(.Error) {
            level = "Error"
        } else if logMessage.flag.contains(.Warning) {
            level = "Warning"
        } else if logMessage.flag.contains(.Info) {
            level = "Info"
        } else if logMessage.flag.contains(.Debug) {
            level = "Debug"
        } else if logMessage.flag.contains(.Verbose) {
            level = "Verbose"
        }


        let components = NSCalendar.autoupdatingCurrentCalendar().components(RangicLogFormatter.calUnits, fromDate: logMessage.timestamp)
        let epoch = logMessage.timestamp.timeIntervalSinceReferenceDate
        let msecs = Int((epoch - floor(epoch)) * 1000)

        let timestamp = NSString(format: "%04d-%02d-%02d %02d:%02d:%02d.%03d", components.year, components.month, components.day, components.hour, components.minute, components.second, msecs)

        return "\(timestamp) [\(RangicLogFormatter.appName):\(logMessage.threadID)] [\(level)] \(logMessage.message)"
    }
}