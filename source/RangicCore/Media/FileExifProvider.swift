//
//  Radish
//

import Foundation
import SwiftyJSON

open class FileExifProvider
{
    static open func getDetails(_ filename: String) -> [MediaDataDetail]
    {
        var result = [MediaDataDetail]()
        let json = JSON(data:NSData(data: runExifTool(filename).data(using: String.Encoding.utf8)!) as Data)
        if json.count == 1 {
            for (childKey, childValue) in json[0] {
                var addedCategory = false
                for (grandChildKey, grandChildValue) in childValue {
                    if grandChildValue.stringValue.hasPrefix("(Binary data ") {
                        continue
                    }

                    let path = "\(childKey).\(grandChildKey)"
                    if includeInProperties.contains(path) {
                        result = addSpecialProperty(result, name: grandChildKey, value: getJsonValue(grandChildValue))
                    }

                    if excludeProperties.contains(childKey) {
                        continue
                    }

                    var isExcluded = false
                    for element in excludeElements {
                        if path.hasPrefix(element) {
                            isExcluded = true
                            break
                        }
                    }
                    if isExcluded {
                        continue
                    }

                    if !addedCategory {
                        result.append(MediaDataDetail(category: childKey, name: nil, value: nil))
                        addedCategory = true
                    }

                    result.append(MediaDataDetail(category: nil, name: grandChildKey, value: getJsonValue(grandChildValue)))
                }
            }
        }

        return result
    }

    static fileprivate func getJsonValue(_ json: JSON) -> String
    {
        if json.type == .array {
            var val = [String]()
            let array = json.arrayValue
            for v in array {
                val.append(v.stringValue)
            }
            return val.joined(separator: ", ")
        }
        return json.stringValue
    }

    static fileprivate func addSpecialProperty(_ allProperties: [MediaDataDetail], name: String, value: String) -> [MediaDataDetail]
    {
        var props = allProperties
        if props.count < 1 {
            props.append(MediaDataDetail(category: specialProperty, name: nil, value: nil))
            props.append(MediaDataDetail(category: nil, name: name, value: value))
            return props
        }
        else if props[0].category != specialProperty {
            props.insert(MediaDataDetail(category: specialProperty, name: nil, value: nil), at: 0)
        }

        props.insert(MediaDataDetail(category: nil, name: name, value: value), at: 1)
        return props
    }

    static fileprivate func runExifTool(_ filename: String) -> String
    {
        let process = ProcessInvoker.run("/usr/local/bin/exiftool", arguments: ["-a", "-j", "-g", filename])
        if process.exitCode == 0 {
            return process.output
        }
        else {
            Logger.error("exiftool failed: \(process.exitCode); error: '\(process.error)'")
        }

        return ""
    }

    static fileprivate let specialProperty = "Properties"
    static fileprivate let includeInProperties: Set<String> =
    [
        "File.FileSize",
        "File.FileModifyDate",
        "File.Comment",
        "EXIF.Make",
        "EXIF.Model",
        "EXIF.ExposureTime",
        "EXIF.FNumber",
        "EXIF.CreateDate",
        "EXIF.ShutterSpeedValue",
        "EXIF.ApertureValue",
        "EXIF.ISO",
        "EXIF.FocalLength",
        "EXIF.LensModel",
        "XMP.Subject",
        "IPTC.Keywords",
        "Composite.GPSPosition",
        "Composite.ImageSize"
    ]

    static fileprivate let excludeProperties: Set<String> =
    [
        "ExifTool",
        "File"
    ]

    static fileprivate let excludeElements: Set<String> =
    [
        "ICC_Profile.ProfileDescriptionML"
    ]
}
