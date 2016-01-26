//
//

import AVFoundation

public class SupportedMediaTypes
{
    public enum MediaType
    {
        case Image, Video, Unknown
    }

    static public var includeRawImages = false

    static private var imageTypes:[String]? = nil
    static private var videoTypes:[String]? = nil

    static private var supportedTypes:[String]? = nil


    static public func all() -> [String]
    {
        if (supportedTypes == nil) {
            supportedTypes = [String]()
            supportedTypes!.appendContentsOf(images())
            supportedTypes!.appendContentsOf(videos())
        }
        return supportedTypes!;
    }

    static public func getTypeFromFileExtension(fileExtension: String) -> MediaType
    {
        if fileExtension.characters.count > 0 {
            let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil)!.takeRetainedValue()

            if images().contains(uti as String) {
                return MediaType.Image
            }

            if videos().contains(uti as String) {
                return MediaType.Video
            }
        }

        return MediaType.Unknown
    }

    static public func isSupportedFile(fullUrl:NSURL) -> Bool
    {
        return all().contains(getFileType(fullUrl))
    }

    static public func getType(fullUrl:NSURL) -> MediaType
    {
        let fileType = getFileType(fullUrl)

        if images().contains(fileType) {
            return MediaType.Image
        }

        if videos().contains(fileType) {
            return MediaType.Video
        }

        return MediaType.Unknown
    }

    static public func images() -> [String]
    {
        if (imageTypes == nil) {
            let cgImageTypes: NSArray = CGImageSourceCopyTypeIdentifiers()
            imageTypes = [String]()

            // Filter out the slow-loading RAW iamge types; this preference can be exposed if it's ever important
            for cgType in cgImageTypes {
                let type = cgType as! String
                if includeRawImages || !type.containsString("raw") {
                    imageTypes?.append(type)
                }
            }
        }
        return imageTypes!;
    }

    static public func videos() -> [String]
    {
        if (videoTypes == nil) {
            videoTypes = [AVFileTypeAIFC, AVFileTypeAIFF, AVFileTypeCoreAudioFormat, AVFileTypeAppleM4V, AVFileTypeMPEG4,
                AVFileTypeAppleM4A, AVFileTypeQuickTimeMovie, AVFileTypeWAVE, AVFileTypeAMR, AVFileTypeAC3, AVFileTypeMPEGLayer3, AVFileTypeSunAU]
        }
        return videoTypes!
    }

    static public func getFileType(fullUrl:NSURL) -> String
    {
        var uti:AnyObject?
        do {
            try fullUrl.getResourceValue(&uti, forKey:NSURLTypeIdentifierKey)
            return uti as! String
        }
        catch {
            return ""
        }
    }
}