/// Extensions for converting Plist values to Bool.

// MARK: - Bool from Plist

extension Bool {
    /// Creates a boolean from a Plist boolean value.
    ///
    /// Returns `nil` if the Plist value is not a boolean.
    ///
    /// - Parameter plist: The Plist value.
    @inlinable
    public init?(_ plist: Plist) {
        guard case .bool(let value) = plist.raw else { return nil }
        self = value
    }
}
