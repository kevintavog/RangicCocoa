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
    private var xmpAtomData = [String: String]()

    private var xmpDate: NSDate? = nil

    public private(set) var location: Location? = nil
    public private(set) var timestamp: NSDate? = nil
    public private(set) var keywords: [String]? = nil
    public private(set) var mediaSize: MediaSize? = nil
    public private(set) var rotation: Int? = nil
    public private(set) var compatibleBrands = [String]()


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
                    Logger.warn("Failed reading atom at \(offset)")
                    break
                }
            }
        }

        parseFtypAtom()
        parseUuidAtom()
        parseMetaAtom()
        parseTrakAtom()
        parseXmpAtom()


        // Determine the location
        if location == nil {
            location = getLocationFrom(uuidData)
        }

        if location == nil {
            location = getLocationFrom(xmpAtomData)
        }

        if location == nil {
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
                    Logger.error("Error parsing moov location (\(moovLocation)): \(error)")
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

        if let mvhdAtom = getAtom(rootAtoms, atomPath: ["moov", "mvhd"]) {
            // The created date is 4 bytes into the data of the atom; the date is the number
            // of seconds since Jan 1, 1904

            // 66 years + 17 leap days
            let secondsBetween1904And1970 = UInt32(66 * 365 * 24 * 60 * 60) + UInt32(17 * 24 * 60 * 60)

            let mvhdReader = DataReader(data: getData(mvhdAtom))
            mvhdReader.offset = 4
            let createSeconds = mvhdReader.readUInt32()
            if createSeconds >= secondsBetween1904And1970 {
                timestamp = NSDate(timeIntervalSince1970: NSTimeInterval(createSeconds - secondsBetween1904And1970))
            }
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

    private func getLocationFrom(data: [String:String]) -> Location?
    {
        if let dataLatitude = data["GPSLatitude"] {
            if let dataLongitude = data["GPSLongitude"] {

                let latMatches = parseUuidLatLong(dataLatitude)
                let lonMatches = parseUuidLatLong(dataLongitude)

                let latitude = convertToGeo(latMatches[0], minutesAndSeconds: latMatches[1])
                let longitude = convertToGeo(lonMatches[0], minutesAndSeconds: lonMatches[1])

                return Location(latitude: latitude, latitudeReference: latMatches[2], longitude: longitude, longitudeReference: lonMatches[2])
            }
        }

        return nil
    }

    private func parseUuidAtom()
    {
        if let uuidAtom = getAtom(rootAtoms, atomPath: ["uuid"]) {

            // The atom data is 16 bytes of unknown data followed by XML
            let uuidReader = DataReader(data: getData(uuidAtom))
            if uuidReader.data.length >= 56 {
                // Skip the 16 bytes of unknown data
                uuidReader.readUInt64()
                uuidReader.readUInt64()

                // The remaining is xml - atom length - 4 bytes for length - 4 bytes for type - 16 bytes unknown
                let xmlString = uuidReader.readString(UInt32(uuidAtom.length - 4 - 4 - 16))
                uuidData = parseXml(xmlString)
            }
        }
    }

    private func parseFtypAtom()
    {
        if let ftypAtom = getAtom(rootAtoms, atomPath: ["ftyp"]) {
            // FTYP data is:
            //      4 bytes: major brand
            //      4 bytes: minor version
            //      4 bytes EACH: compatible brands
            let ftypReader = DataReader(data: getData(ftypAtom))

            let majorBrandAndMinorVersion = 8
            ftypReader.offset = majorBrandAndMinorVersion

            while ftypReader.offset < ftypReader.data.length {
                compatibleBrands.append(ftypReader.readString(4))
            }
        }
    }

    private func parseXmpAtom()
    {
        if let xmpAtom = getAtom(rootAtoms, atomPath: ["moov", "udta", "XMP_"]) {
            let xmpReader = DataReader(data: getData(xmpAtom))
            let xmlString = xmpReader.readString(UInt32(xmpAtom.length - 4 - 4))
            xmpAtomData = parseXml(xmlString)
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

    private func parseTrakAtom()
    {
        var trakAtoms = [VideoAtom]()

        // 'moov' can have multiple 'trak' atoms, we'll search each trak instance
        if let moovAtom = getAtom(rootAtoms, atomPath: ["moov"]) {
            for moovChild in moovAtom.children {
                if moovChild.type == "trak" {
                    trakAtoms.append(moovChild)
                }
            }
        }

        // Find 'trak' that has both a video ('vide') 'hdlr' and 'stsd', grab the width & height
        for trak in trakAtoms {
            parseAtom(trak.offset + 8, atomLength: trak.length, children: &trak.children)

            if let tkhdAtom = getAtom(trak.children, atomPath: ["tkhd"]) {
                let tkhdReader = DataReader(data: getData(tkhdAtom))
                tkhdReader.offset = 40
                let widthScale = asFloat32(tkhdReader.readUInt32())
                let widthRotation = asFloat32(tkhdReader.readUInt32())
                var floatRotation = atan2(widthRotation, widthScale) * 180.0 / Float(M_PI)
                if floatRotation < 0 {
                    floatRotation += 360
                }
                rotation = Int(round(floatRotation))
            }

            if let hdlrAtom = getAtom(trak.children, atomPath: ["edts", "mdia", "hdlr"]),
                let stsdAtom = getAtom(trak.children, atomPath: ["edts", "mdia", "minf", "dinf", "stbl", "stsd"]) {

                    let hdlrReader = DataReader(data: getData(hdlrAtom))
                    hdlrReader.offset = 8
                    let mediaType = hdlrReader.readString(4)
                    if mediaType == "vide" {
                        let stsdReader = DataReader(data: getData(stsdAtom))
                        stsdReader.offset = 40

                        let width = stsdReader.readUInt16()
                        let height = stsdReader.readUInt16()

                        mediaSize = MediaSize(width: Int(width), height: Int(height))
                        break
                    }
            }
        }
    }

    private func asFloat32(number: UInt32) -> Float32
    {
        switch number {
        case 0xFFFF0000:
            return -1
        case 0x00010000:
            return 1
        case 0x00000000:
            return 0
        default:
            Logger.error("Unexpected UInt32->Float32 conversion: \(number)")
            return Float32.quietNaN
        }
    }

    private func parseXml(xmlString: String) -> [String:String]
    {
        var data = [String:String]()
        do {
            let xmlDoc = try NSXMLDocument(XMLString: xmlString, options: 0)

            // Add namespaces to get xpath to work
            xmlDoc.rootElement()?.addNamespace(NSXMLNode.namespaceWithName("exif", stringValue: "http://ns.adobe.com/exif/1.0/") as! NSXMLNode)
            xmlDoc.rootElement()?.addNamespace(NSXMLNode.namespaceWithName("xmp", stringValue: "http://ns.adobe.com/xap/1.0/") as! NSXMLNode)
            xmlDoc.rootElement()?.addNamespace(NSXMLNode.namespaceWithName("dc", stringValue: "http://purl.org/dc/elements/1.1/") as! NSXMLNode)
            xmlDoc.rootElement()?.addNamespace(NSXMLNode.namespaceWithName("rdf", stringValue: "http://www.w3.org/1999/02/22-rdf-syntax-ns#") as! NSXMLNode)


            let exifNodes = try xmlDoc.nodesForXPath("//exif:*")
            for node in exifNodes {
                data[node.localName!] = node.stringValue!
            }

            let xmpNodes = try xmlDoc.nodesForXPath("//xmp:CreateDate")
            for node in xmpNodes {
                data[node.localName!] = node.stringValue!
            }

            var subjectItems = [String]()
            let subjectNodes = try xmlDoc.nodesForXPath(".//dc:subject/rdf:Bag")
            for node in subjectNodes {
                for child in node.children! {
                    subjectItems.append(child.stringValue!)
                }
            }

            if subjectItems.count > 0 {
                keywords = subjectItems
            }

        } catch let error {
            Logger.error("Exception parsing xml: \(error)\n\"\(xmlString)\"")
        }
        return data
    }

    private func logTree(atom: VideoAtom, parent: String)
    {
        Logger.info("\(parent) offset: \(atom.offset), length: \(atom.length)")
        let path = "\(parent)\\\(atom.type)"
        Logger.info("\(path) children are:")
        logTreeChildren(atom, parent: path)
    }

    private func logTreeChildren(atom: VideoAtom, parent: String)
    {
        if atom.children.count == 0 {
            parseAtom(atom.offset + 8, atomLength: atom.length, children: &atom.children)
        }

        for child in atom.children {
            Logger.info("\(parent)\\\(child.type), @\(child.offset) for \(child.length)")
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

        #if DEBUG_ATOMS
        var childNames = [String]()
        for child in children {
            childNames.append(child.type)
        }

        Logger.warn("Unable to find '\(atomPath)' in \(childNames)")
        #endif

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
                    Logger.warn("Failed reading atom at \(offset)")
                    break
                }
            }
        }
    }

    private func nextAtom(offset: UInt64) -> VideoAtom?
    {
        let dataLength = fileHandle!.readDataOfLength(4)
        if dataLength == 0 {
            return nil
        }

        var length: UInt32 = 0
        dataLength.getBytes(&length, length: 4)
        if length == 0 {
            return nil
        }

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

    private func byteArrayToString(data: NSData, offset: Int, length: Int) -> String
    {
        let str = NSMutableString(capacity: length * 3)
        var byte: UInt8 = 0
        for index in offset..<offset+length {
            data.getBytes(&byte, range: NSMakeRange(index, 1))
            str.appendFormat("%02X", byte)
            if ((index + 1) % 8) == 0 {
                str.appendString(" ")
            }
        }
        return str as String
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
//Logger.warn("atom at \(offset): \(type), \(length) bytes long")
        self.type = type
        self.offset = offset
        self.length = length
    }
}
