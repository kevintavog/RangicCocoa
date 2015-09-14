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
                        result = addSpecialProperty(result, name: grandChildKey, value: grandChildValue.stringValue)
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

                    result.append(MediaDataDetail(category: nil, name: grandChildKey, value: grandChildValue.stringValue))
                }
            }
        }

        return result
    }

    static private func addSpecialProperty(var allProperties: [MediaDataDetail], name: String, value: String) -> [MediaDataDetail]
    {
        if allProperties.count < 1 {
            allProperties.append(MediaDataDetail(category: specialProperty, name: nil, value: nil))
            allProperties.append(MediaDataDetail(category: nil, name: name, value: value))
            return allProperties
        }
        else if allProperties[0].category != specialProperty {
            allProperties.insert(MediaDataDetail(category: specialProperty, name: nil, value: nil), atIndex: 0)
        }

        allProperties.insert(MediaDataDetail(category: nil, name: name, value: value), atIndex: 1)
        return allProperties
    }

    static private func runExifTool(filename: String) -> String
    {
        let process = ProcessInvoker.run("/usr/bin/exiftool", arguments: ["-a", "-j", "-g", filename])
        if process.exitCode == 0 {
            return process.output
        }
        else {
            Logger.log("exiftool failed: \(process.exitCode); error: '\(process.error)'")
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