//
//  Radish
//

import CocoaLumberjackSwift

public class Logger
{
    static public func configure()
    {
        DDLog.addLogger(DDTTYLogger.sharedInstance())

        let fileLogger = DDFileLogger()
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

    static public func log(message:String)
    {
        DDLogInfo("\(message)")
    }
}