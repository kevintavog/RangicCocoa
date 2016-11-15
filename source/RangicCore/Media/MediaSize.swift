//
//  MediaSize.swift
//

open class MediaSize
{
    open fileprivate(set) var width: Int
    open fileprivate(set) var height: Int

    public init(width: Int, height: Int)
    {
        self.width = width
        self.height = height
    }

    open var description: String
    {
        return "\(width) x \(height)"
    }
}
