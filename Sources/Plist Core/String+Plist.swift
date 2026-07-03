// Extensions for converting Plist values to String.

// MARK: - String from Plist

extension String {
    /// Creates a string from a Plist string value.
    ///
    /// Returns the string value if this is a Plist string,
    /// otherwise returns an empty string.
    ///
    /// - Parameter plist: The Plist value.
    @inlinable
    public init(_ plist: Plist) {
        if case .string(let value) = plist.raw {
            self = value
        } else {
            self = ""
        }
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
