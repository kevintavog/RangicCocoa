//
//  RangicCore
//

extension String
{
    // Returns a substring as denoted by an NSRange
    public func substringWithRange(range: NSRange) -> String
    {
        let startIndex = self.startIndex.advancedBy(range.location)
        let endIndex = startIndex.advancedBy(range.length)
        let rangeIndex = Range(start: startIndex, end: endIndex)
        return self.substringWithRange(rangeIndex)
    }
}

extension String
{
    public func regexGroups(pattern: String) throws -> [String]
    {
        let regex = try NSRegularExpression(pattern: pattern, options: .CaseInsensitive)

        var groups = [String]()
        for match in regex.matchesInString(self, options: .WithoutAnchoringBounds, range: NSMakeRange(0, self.characters.count)) {
            groups.append(self.substringWithRange(match.range))
        }
        return groups
    }
}

