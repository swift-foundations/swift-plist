extension Int {

    @inlinable
    public init?(_ plist: Plist) {
        guard case .integer(let value) = plist.raw else { return nil }
        guard let result = Int(exactly: value) else { return nil }
        self = result
    }
}

extension Int64 {

    @inlinable
    public init?(_ plist: Plist) {
        guard case .integer(let value) = plist.raw else { return nil }
        self = value
    }
}
