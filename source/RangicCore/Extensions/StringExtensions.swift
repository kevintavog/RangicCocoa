//
//  RangicCore
//

extension String
{
    // Returns a substring as denoted by an NSRange
    public func substringWithRange(_ range: NSRange) -> String
    {
        let startIndex = self.characters.index(self.startIndex, offsetBy: range.location)
        let endIndex = self.characters.index(startIndex, offsetBy: range.length)
        return self.substring(with: startIndex..<endIndex)
    }

    public func substringFromOffset(_ offset: Int) -> String
    {
        let startIndex = self.characters.index(self.startIndex, offsetBy: offset)
        return self.substring(from: startIndex)
    }
}

extension String
{
    public func relativePathFromBase(_ base: String) -> String
    {
        if self.lowercased().hasPrefix(base.lowercased()) {
            var path = self.substringFromOffset(base.characters.count)
            if path[path.startIndex] == "/" {
                path = path.substringFromOffset(1)
            }
            return path
        } else {
            return self
        }
    }

    public func stringByAppendingPath(_ pathComponent: String) -> String
    {
        return NSString(string: self).appendingPathComponent(pathComponent) as String
    }
}

extension String
{
    public func regexGroups(_ pattern: String) throws -> [String]
    {
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)

        var groups = [String]()
        for match in regex.matches(in: self, options: .withoutAnchoringBounds, range: NSMakeRange(0, self.characters.count)) {
            groups.append(self.substringWithRange(match.range))
        }
        return groups
    }
}

