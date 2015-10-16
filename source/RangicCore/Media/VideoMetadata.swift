//
//  RangicCore
//

public class VideoMetadata
{
    private var fileHandle: NSFileHandle! = nil
    private var fileLength: UInt64! = 0

    private var rootAtoms = [VideoAtom]()

    private var moovData = [String: String]()
    private var uuidData = [String: String]()


    public private(set) var location: Location? = nil
    public private(set) var timestamp: NSDate? = nil
    public private(set) var keywords: [String]? = nil

    // duration seconds (float/double)


    public init?(filename: String)
    {
        fileHandle = NSFileHandle(forReadingAtPath: filename)
        if fileHandle == nil {
            return nil
        }

        do {
            let attr : NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(filename)
            if attr != nil {
                fileLength = attr!.fileSize()
            }
        } catch {
            return nil
        }

        parse()

        fileHandle.closeFile()
        fileHandle = nil
    }

    deinit
    {
        if fileHandle != nil {
            fileHandle.closeFile()
        }
    }

    private func parse()
    {
        // Parse the top-level atoms; we'll drill down as needed later
        var offset: UInt64 = 0
        if let firstAtom = nextAtom(offset) {
            rootAtoms.append(firstAtom)
            offset += firstAtom.length
            while offset < fileLength {
                fileHandle.seekToFileOffset(offset)
                if let atom = nextAtom(offset) {
                    rootAtoms.append(atom)
                    parseAtom(offset + 8, atomLength: atom.length, children: &atom.children)
                    offset += atom.length
                }
                else {
                    Logger.log("Failed reading atom at \(offset)")
                    break
                }
            }
        }

        parseUuidAtom()
        parseMetaAtom()


        // Determine the location
        if let moovLocation = moovData["com.apple.quicktime.location.ISO6709"] {
            do {
                let regex = try NSRegularExpression(pattern: "([\\+-]\\d+\\.\\d+)", options: .CaseInsensitive)
                let matches = regex.matchesInString(moovLocation, options: .WithoutAnchoringBounds, range: NSMakeRange(0, moovLocation.characters.count))
                if matches.count >= 2 {
                    if let latitude = Double(moovLocation.substringWithRange(matches[0].range)) {
                        if let longitude = Double(moovLocation.substringWithRange(matches[1].range)) {
                            location = Location(latitude: latitude, longitude: longitude)
                        }
                    }
                }

            } catch let error {
                Logger.log("Error moov parsing location (\(moovLocation)): \(error)")
            }
        }

        if location == nil {
            if let uuidLatitude = uuidData["GPSLatitude"] {
                if let uuidLongitude = uuidData["GPSLongitude"] {

                    let latMatches = parseUuidLatLong(uuidLatitude)
                    let lonMatches = parseUuidLatLong(uuidLongitude)

                    let latitude = convertToGeo(latMatches[0], minutesAndSeconds: latMatches[1])
                    let longitude = convertToGeo(lonMatches[0], minutesAndSeconds: lonMatches[1])

                    location = Location(latitude: latitude, latitudeReference: latMatches[2], longitude: longitude, longitudeReference: lonMatches[2])
                }
            }
        }

        // Determine the (creation) timestamp
        if let moovDate = moovData["com.apple.quicktime.creationdate"] {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXX"
            dateFormatter.timeZone = NSTimeZone(name: "UTC")
            timestamp = dateFormatter.dateFromString(moovDate)
        }

        if timestamp == nil {
            if let uuidDate = uuidData["CreateDate"] {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                dateFormatter.timeZone = NSTimeZone(name: "UTC")
                timestamp = dateFormatter.dateFromString(uuidDate)
            }
        }
    }

    private func parseUuidAtom()
    {
        if let uuidAtom = getAtom(rootAtoms, atomPath: ["uuid"]) {

            // The atom data is 16 bytes of unknown data followed by XML
            let uuidReader = DataReader(data: getData(uuidAtom))

            // Skip the 16 bytes of unknown data
            uuidReader.readUInt64()
            uuidReader.readUInt64()

            // The remaining is xml - atom length - 4 bytes for length - 4 bytes for type - 16 bytes unknown
            let xmlString = uuidReader.readString(UInt32(uuidAtom.length - 4 - 4 - 16))

            do {
                let xmlDoc = try NSXMLDocument(XMLString: xmlString, options: 0)

                // Add namespaces to get xpath to work
                xmlDoc.rootElement()?.addNamespace(NSXMLNode.namespaceWithName("exif", stringValue: "http://ns.adobe.com/exif/1.0/") as! NSXMLNode)
                xmlDoc.rootElement()?.addNamespace(NSXMLNode.namespaceWithName("xmp", stringValue: "http://ns.adobe.com/xap/1.0/") as! NSXMLNode)
                xmlDoc.rootElement()?.addNamespace(NSXMLNode.namespaceWithName("dc", stringValue: "http://purl.org/dc/elements/1.1/") as! NSXMLNode)
                xmlDoc.rootElement()?.addNamespace(NSXMLNode.namespaceWithName("rdf", stringValue: "http://www.w3.org/1999/02/22-rdf-syntax-ns#") as! NSXMLNode)


                let exifNodes = try xmlDoc.nodesForXPath("//exif:*")
                for node in exifNodes {
                    uuidData[node.localName!] = node.stringValue!
                }

                let xmpNodes = try xmlDoc.nodesForXPath("//xmp:CreateDate")
                for node in xmpNodes {
                    uuidData[node.localName!] = node.stringValue!
                }

                var subjectItems = [String]()
                let subjectNodes = try xmlDoc.nodesForXPath(".//dc:subject/rdf:Bag")
                for node in subjectNodes {
                    for child in node.children! {
                        Logger.log("Adding subject: \(child.stringValue!)")
                        subjectItems.append(child.stringValue!)
                    }
                }

                if subjectItems.count > 0 {
                    keywords = subjectItems
                }

            } catch let error {
                Logger.log("Exception parsing uuid xml: \(error)")
            }
        }
    }

    private func parseMetaAtom()
    {
        if let keysAtom = getAtom(rootAtoms, atomPath: ["moov", "meta", "keys"]) {
            if let ilstAtom = getAtom(rootAtoms, atomPath: ["moov", "meta", "ilst"]) {

                // Keys are easy - a count of all keys, each item is a length/string combo
                let keyReader = DataReader(data: getData(keysAtom))
                let keyCount = Int(keyReader.readUInt64())
                var keys = [String]()
                for _ in 1...keyCount {
                    let fullKeyName = keyReader.readLengthAndString()
                    // Skip "mdta'
                    let keyName = fullKeyName.substringFromIndex(fullKeyName.startIndex.advancedBy(4))
                    keys.append(keyName)
                }

                // Values are more complex, each element is:
                //      4 bytes     - Unknown
                //      4 bytes     - Index
                //      4 bytes     - length
                //      4 bytes     - 'd' 'a' 't' 'a'
                //      8 bytes     - Unknown, possibly the type
                //      remaining   - data (dataLength - 16)
                let valueReader = DataReader(data: getData(ilstAtom))
                var values = [String](count: Int(keyCount), repeatedValue: "")
                for _ in 1...keyCount {
                    valueReader.readUInt32()                    // Unknown
                    let index = valueReader.readUInt32()
                    let dataLength = valueReader.readUInt32()
                    valueReader.readUInt32()                    // 'd' 'a' 't' 'a'
                    valueReader.readUInt64()                    // Unknown, possibly type
                    let value = valueReader.readString(dataLength - 16)

                    values.insert(value, atIndex: Int(index - 1))
                }


                for count in 0..<keyCount {
                    moovData[keys[count]] = values[count]
                }
            }
        }
    }

    private func getAtom(children: [VideoAtom], atomPath: [String]) -> VideoAtom?
    {
        for child in children {
            if child.type == atomPath[0] {
                if atomPath.count == 1 {
                    return child
                } else {
                    parseAtom(child.offset + 8, atomLength: child.length, children: &child.children)
                    return getAtom(child.children, atomPath: Array(atomPath[1...atomPath.count - 1]))
                }
            }
        }

        return nil
    }

    private func parseAtom(atomOffset: UInt64, atomLength: UInt64, inout children: [VideoAtom])
    {
        let atomEnd = atomOffset + atomLength
        var offset = atomOffset

        fileHandle.seekToFileOffset(offset)
        if let firstAtom = nextAtom(offset) {
            children.append(firstAtom)

            offset += firstAtom.length
            while offset < fileLength && offset < atomEnd {
                fileHandle.seekToFileOffset(offset)
                if let atom = nextAtom(offset) {
                    children.append(atom)

                    if atom.length == 0 {
                        break
                    }

                    offset += atom.length
                }
                else {
                    Logger.log("Failed reading atom at \(offset)")
                    break
                }

            }
        }
    }

    private func nextAtom(offset: UInt64) -> VideoAtom?
    {
        let dataLength = fileHandle!.readDataOfLength(4)
        var length: UInt32 = 0
        dataLength.getBytes(&length, length: 4)

        let atomType = fileHandle.readDataOfLength(4)
        if let type = String(data: atomType, encoding: NSUTF8StringEncoding) {
            return VideoAtom(type: type, offset: offset, length: UInt64(length.byteSwapped))
        }

        return nil
    }

    private func getData(atom: VideoAtom) -> NSData
    {
        fileHandle.seekToFileOffset(atom.offset + 8)
        return fileHandle.readDataOfLength(Int(atom.length - 8))
    }

    private func convertToGeo(degrees: String, minutesAndSeconds: String) -> Double
    {
        if let degreesNumber = Double(degrees) {
            if let minutesAndSecondsNumber = Double(minutesAndSeconds) {
                return degreesNumber + (minutesAndSecondsNumber / 60.0)
            }
        }

        return 0
    }

    // Splits "47,33.366000N" into ["47", "33.366000", "N"]
    private func parseUuidLatLong(geo: String) -> [String]
    {
        var pieces = [String]()
        let commaIndex = geo.characters.indexOf(",")
        pieces.append(geo.substringToIndex(commaIndex!))
        pieces.append(geo.substringWithRange(commaIndex!.advancedBy(1)..<geo.endIndex.predecessor()))
        pieces.append(geo.substringFromIndex(geo.endIndex.predecessor()))
        return pieces
    }
    
}

class VideoAtom
{
    let offset: UInt64
    let length: UInt64
    let type: String
    var children = [VideoAtom]()


    init(type: String, offset: UInt64, length: UInt64)
    {
        self.type = type
        self.offset = offset
        self.length = length
    }
}
