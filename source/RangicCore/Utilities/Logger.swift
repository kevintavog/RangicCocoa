//
//  RangicCore
//

//import CocoaLumberjack
//import CocoaLumberjackSwift

open class Logger {
    static public func configure() {
//        DDTTYLogger!!.sharedInstance.logFormatter = RangicLogFormatter()
//        DDLog.add(DDTTYLogger!!.sharedInstance)

//        let fileLogger = DDFileLogger()
//        fileLogger.logFormatter = RangicLogFormatter()
//        fileLogger.rollingFrequency = TimeInterval(24 * 60 * 60)
//        fileLogger.logFileManager.maximumNumberOfLogFiles = 10
//        fileLogger.maximumFileSize = UInt64(20 * 1024 * 1024)
//        DDLog.add(fileLogger)
    }

    static public func error(_ message:String) {
        NSLog("ERROR: \(message)")
//        DDLogError("\(message)")
    }

    static public func warn(_ message:String) {
        NSLog("WARN: \(message)")
//        DDLogWarn("\(message)")
    }

    static public func info(_ message:String) {
        NSLog("INFO: \(message)")
//        DDLogInfo("\(message)")
    }

    static public func debug(_ message:String) {
        NSLog("DEBUG: \(message)")
//        DDLogDebug("\(message)")
    }

    static public func verbose(_ message:String) {
        NSLog("VERBOSE: \(message)")
//        DDLogVerbose("\(message)")
    }
}

open class RangicLogFormatter : NSObject /*, DDLogFormatter */ {
    static let calUnits = NSCalendar.Unit(rawValue:
        NSCalendar.Unit.year.rawValue
            | NSCalendar.Unit.month.rawValue
            | NSCalendar.Unit.day.rawValue
            | NSCalendar.Unit.hour.rawValue
            | NSCalendar.Unit.minute.rawValue
            | NSCalendar.Unit.second.rawValue)

    static var _cachedAppName: String?
    static var appName: String {
        if _cachedAppName == nil {
            _cachedAppName = ProcessInfo.processInfo.processName
        }
        return _cachedAppName!
    }
/*
    open func format(message logMessage: DDLogMessage) -> String? {
        var level = "<none>"
        if logMessage.flag.contains(.error) {
            level = "Error"
        } else if logMessage.flag.contains(.warning) {
            level = "Warning"
        } else if logMessage.flag.contains(.info) {
            level = "Info"
        } else if logMessage.flag.contains(.debug) {
            level = "Debug"
        } else if logMessage.flag.contains(.verbose) {
            level = "Verbose"
        }


        let components = (Calendar.autoupdatingCurrent as NSCalendar).components(RangicLogFormatter.calUnits, from: logMessage.timestamp)
        let epoch = logMessage.timestamp.timeIntervalSinceReferenceDate
        let msecs = Int((epoch - floor(epoch)) * 1000)

        let timestamp = NSString(format: "%04d-%02d-%02d %02d:%02d:%02d.%03d", components.year!, components.month!, components.day!, components.hour!, components.minute!, components.second!, msecs)

        return "\(timestamp) [\(RangicLogFormatter.appName):\(logMessage.threadID)] [\(level)] \(logMessage.message)"
    }
 */
}
