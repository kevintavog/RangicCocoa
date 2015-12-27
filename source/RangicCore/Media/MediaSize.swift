//
//  MediaSize.swift
//

public class MediaSize
{
    public private(set) var width: Int
    public private(set) var height: Int

    public init(width: Int, height: Int)
    {
        self.width = width
        self.height = height
    }

    public var description: String
    {
        return "\(width) x \(height)"
    }
}
