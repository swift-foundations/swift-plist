/// Plist.Stream.swift
/// swift-plist
///
/// Async Plist parsing support

// MARK: - Async Parse

extension Plist {
    /// Parses a plist from an async byte sequence.
    ///
    /// Collects all bytes before parsing. Auto-detects XML or binary format.
    ///
    /// - Parameter bytes: The async sequence of bytes.
    /// - Returns: The parsed plist.
    /// - Throws: `Plist.Error` if parsing fails.
    @inlinable
    public static func parse<S: AsyncSequence & Sendable>(
        collecting bytes: S
    ) async throws(Plist.Error) -> Plist
    where S.Element == UInt8 {
        var buffer: [UInt8] = []
        do {
            for try await byte in bytes {
                buffer.append(byte)
            }
        } catch {
            throw .unknownFormat
        }
        return try parse(buffer)
    }
}

// MARK: - Serializable Async Support

extension Plist.Serializable {
    /// Creates a value from async plist bytes.
    @inlinable
    public init<S: AsyncSequence & Sendable>(
        collecting bytes: S
    ) async throws(Plist.Error)
    where S.Element == UInt8 {
        let plist = try await Plist.parse(collecting: bytes)
        self = try Self.deserialize(plist)
    }
}
