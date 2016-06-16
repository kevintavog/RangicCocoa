//
//  Radish
//

import Foundation

public class FileExifProvider
{
    static public func getDetails(filename: String) -> [MediaDataDetail]
    {
        var result = [MediaDataDetail]()
        let json = JSON(data:NSData(data: runExifTool(filename).dataUsingEncoding(NSUTF8StringEncoding)!))
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

    static private func getJsonValue(json: JSON) -> String
    {
        if json.type == .Array {
            var val = [String]()
            let array = json.arrayValue
            for v in array {
                val.append(v.stringValue)
            }
            return val.joinWithSeparator(", ")
        }
        return json.stringValue
    }

    static private func addSpecialProperty(allProperties: [MediaDataDetail], name: String, value: String) -> [MediaDataDetail]
    {
        var props = allProperties
        if props.count < 1 {
            props.append(MediaDataDetail(category: specialProperty, name: nil, value: nil))
            props.append(MediaDataDetail(category: nil, name: name, value: value))
            return props
        }
        else if props[0].category != specialProperty {
            props.insert(MediaDataDetail(category: specialProperty, name: nil, value: nil), atIndex: 0)
        }

        props.insert(MediaDataDetail(category: nil, name: name, value: value), atIndex: 1)
        return props
    }

    static private func runExifTool(filename: String) -> String
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

    static private let specialProperty = "Properties"
    static private let includeInProperties: Set<String> =
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

    static private let excludeProperties: Set<String> =
    [
        "ExifTool",
        "File"
    ]

    static private let excludeElements: Set<String> =
    [
        "ICC_Profile.ProfileDescriptionML"
    ]
}