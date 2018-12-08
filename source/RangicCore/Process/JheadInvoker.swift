//
//  JheadInvoker
//

import Foundation

open class JheadInvoker
{
    public let processInvoker: ProcessInvoker

    static public func autoRotate(_ files: [String]) -> JheadInvoker
    {
        let bundlePath = Bundle(for:object_getClass(JheadInvoker.self)!).resourcePath! as NSString
        let launchPath = bundlePath.appendingPathComponent("jhead")

        var args = ["-q", "-autorot", "-ft"]
        for f in files {
            args.append(f)
        }

        let process = ProcessInvoker.run(launchPath, arguments: args)
        return JheadInvoker(processInvoker: process)
    }

    fileprivate init(processInvoker: ProcessInvoker)
    {
        self.processInvoker = processInvoker
    }

}
