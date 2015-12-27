//
//  RangicCore
//

class DataReader
{
    let data: NSData
    var offset: Int

    init(data: NSData)
    {
        self.data = data
        self.offset = 0
    }

    func readString(length: UInt32) -> String
    {
        let length = Int(length)
        let subData = data.subdataWithRange(NSMakeRange(offset, length))
        offset += length
        return String(data: subData, encoding: NSUTF8StringEncoding)!
    }

    func readLengthAndString() -> String
    {
        let length = Int(readUInt32()) - 4
        let subData = data.subdataWithRange(NSMakeRange(offset, length))
        offset += length
        return String(data: subData, encoding: NSUTF8StringEncoding)!
    }

    func readUInt16() -> UInt16
    {
        let val: UInt16 = read()
        return val.bigEndian
    }

    func readUInt32() -> UInt32
    {
        let val: UInt32 = read()
        return val.bigEndian
    }

    func readUInt64() -> UInt64
    {
        let val: UInt64 = read()
        return val.bigEndian
    }

    func read<T>() -> T
    {
        let size = sizeof(T)
        let subData = data.subdataWithRange(NSMakeRange(offset, size))
        offset += size
        return UnsafePointer<T>(subData.bytes).memory
    }
}