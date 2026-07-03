// Extensions for converting Plist values to Double.

// MARK: - Double from Plist

extension Double {
    /// Creates a double from a Plist real or integer value.
    ///
    /// Converts integers to doubles if needed.
    /// Returns `nil` if the Plist value is not a real or integer.
    ///
    /// - Parameter plist: The Plist value.
    @inlinable
    public init?(_ plist: Plist) {
        switch plist.raw {
        case .real(let value):
            self = value

        case .integer(let value):
            self = Double(value)

        default:
            return nil
        }
    }
}

// MARK: - Float from Plist

extension Float {
    /// Creates a float from a Plist real or integer value.
    ///
    /// Converts integers to floats if needed.
    /// Returns `nil` if the Plist value is not a real or integer.
    ///
    /// - Parameter plist: The Plist value.
    @inlinable
    public init?(_ plist: Plist) {
        switch plist.raw {
        case .real(let value):
            self = Float(value)

        case .integer(let value):
            self = Float(value)

        default:
            return nil
        }
    }
}
