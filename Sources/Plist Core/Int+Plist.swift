/// Extensions for converting Plist values to Int.

// MARK: - Int from Plist

extension Int {
    /// Creates an integer from a Plist integer value.
    ///
    /// Returns `nil` if the Plist value is not an integer,
    /// or if the value overflows Int.
    ///
    /// - Parameter plist: The Plist value.
    @inlinable
    public init?(_ plist: Plist) {
        guard case .integer(let value) = plist.raw else { return nil }
        guard let result = Int(exactly: value) else { return nil }
        self = result
    }
}

// MARK: - Int64 from Plist

extension Int64 {
    /// Creates a 64-bit integer from a Plist integer value.
    ///
    /// Returns `nil` if the Plist value is not an integer.
    ///
    /// - Parameter plist: The Plist value.
    @inlinable
    public init?(_ plist: Plist) {
        guard case .integer(let value) = plist.raw else { return nil }
        self = value
    }
}
