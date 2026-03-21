import Plist_Core

extension Plist.Binary {
    /// Binary plist trailer structure (32 bytes at end of file).
    ///
    /// The trailer contains metadata about the plist structure:
    /// - Number of objects
    /// - Root object index
    /// - Offset table location
    /// - Size information for references
    struct Trailer: Sendable {
        /// Bytes 0-4: Unused (reserved).
        let unused: (UInt8, UInt8, UInt8, UInt8, UInt8)

        /// Byte 5: Sort version (0 = unsorted).
        let sortVersion: UInt8

        /// Byte 6: Size of each offset table entry in bytes.
        let offsetIntSize: UInt8

        /// Byte 7: Size of each object reference in bytes.
        let objectRefSize: UInt8

        /// Bytes 8-15: Number of objects in the plist.
        let numObjects: UInt64

        /// Bytes 16-23: Index of the root object.
        let topObject: UInt64

        /// Bytes 24-31: Byte offset of the offset table.
        let offsetTableOffset: UInt64
    }
}

// MARK: - Trailer Parsing

extension Plist.Binary.Trailer {
    /// The size of the trailer in bytes.
    static let size: Int = 32

    /// Parses the trailer from the last 32 bytes of a plist.
    ///
    /// - Parameter bytes: The full plist bytes.
    /// - Returns: The parsed trailer.
    /// - Throws: `Plist.Error` if the trailer is invalid.
    static func parse<Bytes>(
        from bytes: Bytes
    ) throws(Plist.Error) -> Plist.Binary.Trailer
    where Bytes: Collection<UInt8> {
        guard bytes.count >= size else {
            throw .invalidTrailer
        }

        // Get the last 32 bytes
        let trailerStart = bytes.index(bytes.endIndex, offsetBy: -size)
        var index = trailerStart

        // Read unused bytes (5 bytes)
        let u0 = bytes[index]
        index = bytes.index(after: index)
        let u1 = bytes[index]
        index = bytes.index(after: index)
        let u2 = bytes[index]
        index = bytes.index(after: index)
        let u3 = bytes[index]
        index = bytes.index(after: index)
        let u4 = bytes[index]
        index = bytes.index(after: index)

        // Read sortVersion (1 byte)
        let sortVersion = bytes[index]
        index = bytes.index(after: index)

        // Read offsetIntSize (1 byte)
        let offsetIntSize = bytes[index]
        index = bytes.index(after: index)

        // Read objectRefSize (1 byte)
        let objectRefSize = bytes[index]
        index = bytes.index(after: index)

        // Read numObjects (8 bytes, big-endian)
        let numObjects = readBigEndianUInt64(bytes, at: &index)

        // Read topObject (8 bytes, big-endian)
        let topObject = readBigEndianUInt64(bytes, at: &index)

        // Read offsetTableOffset (8 bytes, big-endian)
        let offsetTableOffset = readBigEndianUInt64(bytes, at: &index)

        return Plist.Binary.Trailer(
            unused: (u0, u1, u2, u3, u4),
            sortVersion: sortVersion,
            offsetIntSize: offsetIntSize,
            objectRefSize: objectRefSize,
            numObjects: numObjects,
            topObject: topObject,
            offsetTableOffset: offsetTableOffset
        )
    }

    private static func readBigEndianUInt64<Bytes>(
        _ bytes: Bytes,
        at index: inout Bytes.Index
    ) -> UInt64 where Bytes: Collection<UInt8> {
        var result: UInt64 = 0
        for _ in 0..<8 {
            result = (result << 8) | UInt64(bytes[index])
            index = bytes.index(after: index)
        }
        return result
    }
}
