// MARK: - Factory Methods

extension Plist {
    /// Creates a string plist value.
    @inlinable
    public static func string(_ value: String) -> Plist {
        Plist(.string(value))
    }

    /// Creates an integer plist value from an `Int64`.
    @inlinable
    public static func integer(_ value: Int64) -> Plist {
        Plist(.integer(value))
    }

    /// Creates an integer plist value from an `Int`.
    @inlinable
    public static func integer(_ value: Int) -> Plist {
        Plist(.integer(Int64(value)))
    }

    /// Creates a real (floating-point) plist value.
    @inlinable
    public static func real(_ value: Double) -> Plist {
        Plist(.real(value))
    }

    /// Creates a boolean plist value.
    @inlinable
    public static func bool(_ value: Bool) -> Plist {
        Plist(.bool(value))
    }

    /// Creates a data plist value.
    @inlinable
    public static func data(_ value: [UInt8]) -> Plist {
        Plist(.data(value))
    }

    /// Creates a date plist value.
    ///
    /// - Parameter secondsSinceReferenceDate: Seconds since 2001-01-01 00:00:00 UTC.
    @inlinable
    public static func date(secondsSinceReferenceDate: Double) -> Plist {
        Plist(.date(secondsSinceReferenceDate))
    }

    /// Creates an array plist value.
    @inlinable
    public static func array(_ elements: [Plist]) -> Plist {
        Plist(.array(elements.map(\.raw)))
    }

    /// Creates a dictionary plist value.
    @inlinable
    public static func dictionary(_ members: [(String, Plist)]) -> Plist {
        Plist(.dictionary(members.map { ($0.0, $0.1.raw) }))
    }

    /// A null plist value.
    ///
    /// Used as a placeholder for missing or invalid values.
    @inlinable
    public static var null: Plist {
        Plist(.null)
    }
}
