//
//  Radish
//

import Foundation

public class ProcessInvoker
{
    public let output: String
    public let error: String
    public let exitCode: Int32

    static public func run(launchPath: String, arguments: [String]) -> ProcessInvoker
    {
        let result = ProcessInvoker.launch(launchPath, arguments: arguments)
        let process = ProcessInvoker(output: result.output, error: result.error, exitCode: result.exitCode)
        return process
    }

    private init(output: String, error: String, exitCode: Int32)
    {
        self.output = output
        self.error = error
        self.exitCode = exitCode
    }

    static private func launch(launchPath: String, arguments: [String]) -> (output: String, error: String, exitCode: Int32)
    {
        let task = NSTask()
        task.launchPath = launchPath
        task.arguments = arguments

        let outputPipe = NSPipe()
        task.standardOutput = outputPipe

        let errorPipe = NSPipe()
        task.standardError = errorPipe

        // This executable may depend on another executable in the same folder - make sure the path is updated
        task.environment = ["PATH": (launchPath as NSString).stringByDeletingLastPathComponent]

        task.launch()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)
        return (output!, error!, task.terminationStatus)
    }

    // If you want to do this asynchronously: http://stackoverflow.com/questions/29548811/real-time-nstask-output-to-nstextview-with-swift
    //        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()

    //        var outputObserver: NSObjectProtocol!
    //        outputObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSFileHandleDataAvailableNotification, object: outputPipe.fileHandleForReading, queue: nil) {
    //            notification -> Void in
    //            let data = outputPipe.fileHandleForReading.availableData
    //            if data.length > 0 {
    //                if let str = String(data: data, encoding: NSUTF8StringEncoding) {
    //                    print("Got output: \(str)")
    //                }
    //                outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    //            }
    //            else {
    //                print("EOF error")
    //                NSNotificationCenter.defaultCenter().removeObserver(outputObserver)
    //            }
    //        }


    //        errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()

    //        var errorObserver: NSObjectProtocol!
    //        errorObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSFileHandleDataAvailableNotification, object: errorPipe.fileHandleForReading, queue: nil) {
    //            notification -> Void in
    //            let data = errorPipe.fileHandleForReading.availableData
    //            if data.length > 0 {
    //                if let str = String(data: data, encoding: NSUTF8StringEncoding) {
    //                    print("Got error: \(str)")
    //                }
    //                errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    //            }
    //            else {
    //                print("EOF error")
    //                NSNotificationCenter.defaultCenter().removeObserver(errorObserver)
    //            }
    //        }
}