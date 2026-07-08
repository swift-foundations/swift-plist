import Plist_Core

extension Plist.Binary {
    /// Object type markers in binary plist format.
    ///
    /// The high nibble of the marker byte indicates the type,
    /// and the low nibble often indicates size or is part of the type code.
    enum Marker {}
}

// MARK: - Marker Constants

extension Plist.Binary.Marker {
    // MARK: - Simple Types (0x0n)

    /// Null marker (0x00) - rarely used in practice.
    static let null: UInt8 = 0x00

    /// Boolean false (0x08).
    static let boolFalse: UInt8 = 0x08

    /// Boolean true (0x09).
    static let boolTrue: UInt8 = 0x09

    /// Fill byte (0x0F) - padding.
    static let fill: UInt8 = 0x0F

    // MARK: - Integers (0x1n)

    /// Integer type marker (high nibble).
    static let integerType: UInt8 = 0x10

    // MARK: - Reals (0x2n)

    /// 4-byte float (0x22).
    static let real4: UInt8 = 0x22

    /// 8-byte double (0x23).
    static let real8: UInt8 = 0x23

    // MARK: - Date (0x33)

    /// 8-byte double date (0x33).
    static let date: UInt8 = 0x33

    // MARK: - Data (0x4n)

    /// Data type marker (high nibble).
    static let dataType: UInt8 = 0x40

    // MARK: - ASCII String (0x5n)

    /// ASCII string type marker (high nibble).
    static let asciiType: UInt8 = 0x50

    // MARK: - Unicode String (0x6n)

    /// Unicode string type marker (high nibble).
    static let unicodeType: UInt8 = 0x60

    // MARK: - Array (0xAn)

    /// Array type marker (high nibble).
    static let arrayType: UInt8 = 0xA0

    // MARK: - Dictionary (0xDn)

    /// Dictionary type marker (high nibble).
    static let dictType: UInt8 = 0xD0

    // MARK: - Extended Length Indicator

    /// Indicates extended length follows (low nibble = 0xF).
    static let extendedLength: UInt8 = 0x0F
}

// MARK: - Marker Helpers

extension Plist.Binary.Marker {
    /// Extracts the high nibble (type indicator) from a marker byte.
    @inlinable
    package static func highNibble(_ byte: UInt8) -> UInt8 {
        byte & 0xF0
    }

    /// Extracts the low nibble (size/info) from a marker byte.
    @inlinable
    package static func lowNibble(_ byte: UInt8) -> UInt8 {
        byte & 0x0F
    }

    /// Returns true if the low nibble indicates extended length.
    @inlinable
    package static func hasExtendedLength(_ byte: UInt8) -> Bool {
        lowNibble(byte) == extendedLength
    }
}
