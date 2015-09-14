//
//  JheadInvoker
//

import Foundation

public class JheadInvoker
{
    public let processInvoker: ProcessInvoker

    static public func autoRotate(files: [String]) -> JheadInvoker
    {
        let bundlePath = NSBundle(forClass:object_getClass(JheadInvoker)).resourcePath! as NSString
        let launchPath = bundlePath.stringByAppendingPathComponent("jhead")

        var args = ["-q", "-autorot", "-ft"]
        for f in files {
            args.append(f)
        }

        let process = ProcessInvoker.run(launchPath, arguments: args)
        return JheadInvoker(processInvoker: process)
    }

    private init(processInvoker: ProcessInvoker)
    {
        self.processInvoker = processInvoker
    }

}