import Plist_XML
import Plist_Binary

// MARK: - Parsing

extension Plist {
    /// Parses a plist from bytes, auto-detecting the format.
    ///
    /// - Parameter bytes: The plist bytes (XML or binary).
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.Error` if parsing fails.
    @inlinable
    public static func parse<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        guard let format = Format.detect(bytes) else {
            throw .unknownFormat
        }

        switch format {
        case .xml:
            return try XML.parse(bytes)
        case .binary:
            return try Binary.parse(bytes)
        }
    }

    /// Parses an XML plist from a string.
    ///
    /// - Parameter string: The XML plist string.
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.Error` if parsing fails.
    @inlinable
    public static func parse(xml string: String) throws(Plist.Error) -> Plist {
        try XML.parse(string)
    }

    /// Parses a binary plist from bytes.
    ///
    /// - Parameter bytes: The binary plist bytes.
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.Error` if parsing fails.
    @inlinable
    public static func parse<Bytes>(
        binary bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8> {
        try Binary.parse(bytes)
    }
}

// MARK: - Serialization

extension Plist {
    /// Serializes this plist to the specified format.
    ///
    /// - Parameters:
    ///   - format: The output format (default: `.xml`).
    ///   - pretty: Whether to format with indentation (default: `false`).
    /// - Returns: The serialized bytes.
    @inlinable
    public func serialize(format: Format = .xml, pretty: Bool = false) -> [UInt8] {
        switch format {
        case .xml:
            return XML.serialize(self, pretty: pretty)
        case .binary:
            return Binary.serialize(self)
        }
    }

    /// Serializes this plist to an XML string.
    ///
    /// - Parameter pretty: Whether to format with indentation (default: `false`).
    /// - Returns: The XML string.
    @inlinable
    public func serializeXML(pretty: Bool = false) -> String {
        String(decoding: XML.serialize(self, pretty: pretty), as: UTF8.self)
    }
}

// MARK: - Serializable Convenience

extension Plist.Serializable {
    /// Creates an instance by parsing plist bytes.
    @inlinable
    public init<Bytes>(
        plistBytes bytes: Bytes
    ) throws(Plist.Error)
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        let plist = try Plist.parse(bytes)
        self = try Self.deserialize(plist)
    }

    /// Serializes this value to plist bytes.
    @inlinable
    public func plistBytes(format: Plist.Format = .xml, pretty: Bool = false) -> [UInt8] {
        plist.serialize(format: format, pretty: pretty)
    }

    /// Serializes this value to an XML plist string.
    @inlinable
    public func plistString(pretty: Bool = false) -> String {
        plist.serializeXML(pretty: pretty)
    }
}
