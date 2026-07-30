// Extensions for converting Plist values to String.

// MARK: - String from Plist

extension String {
    /// Creates a string from a Plist string value.
    ///
    /// Returns `nil` if the Plist value is not a string.
    ///
    /// - Parameter plist: The Plist value.
    @inlinable
    public init?(_ plist: Plist) {
        guard case .string(let value) = plist.raw else { return nil }
        self = value
    }
}

extension String {
    /// Creates a string from a Plist string value, if available.
    ///
    /// Returns `nil` if the Plist value is not a string or is null.
    ///
    /// - Parameter plist: The Plist value.
    @inlinable
    public init?(_ plist: Plist?) {
        guard let plist else { return nil }
        guard case .string(let value) = plist.raw else { return nil }
        self = value
    }
}
