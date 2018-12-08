//
//

import AVFoundation

open class SupportedMediaTypes
{
    public enum MediaType
    {
        case image, video, unknown
    }

    static public var includeRawImages = false

    static fileprivate var imageTypes:[String]? = nil
    static fileprivate var videoTypes:[String]? = nil

    static fileprivate var supportedTypes:[String]? = nil


    static public func all() -> [String]
    {
        if (supportedTypes == nil) {
            supportedTypes = [String]()
            supportedTypes!.append(contentsOf: images())
            supportedTypes!.append(contentsOf: videos())
        }
        return supportedTypes!;
    }

    static public func getTypeFromFileExtension(_ fileExtension: String) -> MediaType
    {
        if fileExtension.count > 0 {
            let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)!.takeRetainedValue()

            if images().contains(uti as String) {
                return MediaType.image
            }

            if videos().contains(uti as String) {
                return MediaType.video
            }
        }

        return MediaType.unknown
    }

    static public func isSupportedFile(_ fullUrl:URL) -> Bool
    {
        return all().contains(getFileType(fullUrl))
    }

    static public func getType(_ fullUrl:URL) -> MediaType
    {
        let fileType = getFileType(fullUrl)

        if images().contains(fileType) {
            return MediaType.image
        }

        if videos().contains(fileType) {
            return MediaType.video
        }

        return MediaType.unknown
    }

    static public func images() -> [String]
    {
        if (imageTypes == nil) {
            let cgImageTypes: NSArray = CGImageSourceCopyTypeIdentifiers()
            imageTypes = [String]()

            // Filter out the slow-loading RAW iamge types; this preference can be exposed if it's ever important
            for cgType in cgImageTypes {
                let type = cgType as! String
                if includeRawImages || !type.contains("raw") {
                    imageTypes?.append(type)
                }
            }
        }
        return imageTypes!;
    }

    static public func videos() -> [String]
    {
        if (videoTypes == nil) {
            videoTypes = [AVFileType.aifc.rawValue, AVFileType.aiff.rawValue, AVFileType.caf.rawValue, AVFileType.m4v.rawValue, AVFileType.mp4.rawValue,
                AVFileType.m4a.rawValue, AVFileType.mov.rawValue, AVFileType.wav.rawValue, AVFileType.amr.rawValue, AVFileType.ac3.rawValue, AVFileType.mp3.rawValue, AVFileType.au.rawValue]
        }
        return videoTypes!
    }

    static public func getFileType(_ fullUrl:URL) -> String
    {
        var uti:AnyObject?
        do {
            try (fullUrl as NSURL).getResourceValue(&uti, forKey:URLResourceKey.typeIdentifierKey)
            return uti as! String
        }
        catch {
            return ""
        }
    }
}
