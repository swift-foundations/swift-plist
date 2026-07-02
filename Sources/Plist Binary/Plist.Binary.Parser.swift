import Plist_Core

// MARK: - Parsing

extension Plist.Binary {
    /// Parses a binary plist from bytes.
    ///
    /// - Parameter bytes: The binary plist bytes.
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.Error` if parsing fails.
    public static func parse<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8> {
        let context = try Context(bytes)
        return try context.parseRoot()
    }
}

// MARK: - Parser Context

extension Plist.Binary {
    /// Internal parsing context.
    // WHY: Category D — structural Sendable workaround.
    // WHY: Generic Collection<UInt8> parameter blocks structural Sendable
    // WHY: inference. Single-threaded parser state with mutable parsedObjects.
    // WHY: No caller invariant to uphold — parse is single-threaded.
    // WHEN TO REMOVE: When compiler gains structural Sendable inference through
    // WHEN TO REMOVE: generic Collection parameters.
    // TRACKING: unsafe-audit-findings.md Category D; SP-4.
    final class Context<Bytes: Swift.Collection<UInt8>>: @unchecked Sendable {
        let bytes: Bytes
        let trailer: Trailer
        let offsets: [UInt64]
        var parsedObjects: [UInt64: Plist.Value] = [:]

        init(_ bytes: Bytes) throws(Plist.Error) {
            self.bytes = bytes

            // Validate magic number
            try Self.validateMagic(bytes)

            // Parse trailer
            self.trailer = try Trailer.parse(from: bytes)

            // Parse offset table
            self.offsets = try Self.parseOffsetTable(bytes, trailer: trailer)
        }

        func parseRoot() throws(Plist.Error) -> Plist {
            let rootIndex = trailer.topObject
            let value = try parseObject(at: rootIndex)
            return Plist(value)
        }
    }
}

// MARK: - Magic Validation

/// Binary plist magic bytes: "bplist"
private let _binaryPlistMagic: [UInt8] = [0x62, 0x70, 0x6C, 0x69, 0x73, 0x74]

extension Plist.Binary.Context {
    static func validateMagic(_ bytes: Bytes) throws(Plist.Error) {
        guard bytes.count >= 8 else {
            throw .invalidMagic
        }

        var index = bytes.startIndex
        for expected in _binaryPlistMagic {
            guard bytes[index] == expected else {
                throw .invalidMagic
            }
            index = bytes.index(after: index)
        }

        // Check version (00 or 01)
        let v0 = bytes[index]
        index = bytes.index(after: index)
        let v1 = bytes[index]

        guard v0 == 0x30 else { // '0'
            throw .unsupportedVersion("\(v0)\(v1)")
        }

        guard v1 == 0x30 || v1 == 0x31 else { // '0' or '1'
            throw .unsupportedVersion("0\(Character(UnicodeScalar(v1)))")
        }
    }
}

// MARK: - Offset Table

extension Plist.Binary.Context {
    static func parseOffsetTable(
        _ bytes: Bytes,
        trailer: Plist.Binary.Trailer
    ) throws(Plist.Error) -> [UInt64] {
        let offsetIntSize = Int(trailer.offsetIntSize)
        let numObjects = Int(trailer.numObjects)
        let tableOffset = Int(trailer.offsetTableOffset)

        guard tableOffset + (numObjects * offsetIntSize) <= bytes.count else {
            throw .invalidTrailer
        }

        var offsets: [UInt64] = []
        offsets.reserveCapacity(numObjects)

        var index = bytes.index(bytes.startIndex, offsetBy: tableOffset)
        for _ in 0..<numObjects {
            let offset = readUnsignedInt(bytes, at: &index, size: offsetIntSize)
            offsets.append(offset)
        }

        return offsets
    }
}

// MARK: - Object Parsing

extension Plist.Binary.Context {
    func parseObject(at objectIndex: UInt64) throws(Plist.Error) -> Plist.Value {
        // Check for circular references
        if let cached = parsedObjects[objectIndex] {
            return cached
        }

        guard objectIndex < offsets.count else {
            throw .invalidObjectReference(objectIndex)
        }

        let offset = Int(offsets[Int(objectIndex)])
        guard offset < bytes.count else {
            throw .invalidObjectReference(objectIndex)
        }

        var index = bytes.index(bytes.startIndex, offsetBy: offset)
        let marker = bytes[index]
        index = bytes.index(after: index)

        let value: Plist.Value

        switch marker {
        // Simple types
        case Plist.Binary.Marker.null:
            value = .null

        case Plist.Binary.Marker.boolFalse:
            value = .bool(false)

        case Plist.Binary.Marker.boolTrue:
            value = .bool(true)

        case Plist.Binary.Marker.fill:
            value = .null

        // Integers (0x1n where n indicates byte size power of 2)
        case 0x10...0x1F:
            let sizeCode = Plist.Binary.Marker.lowNibble(marker)
            let byteCount = 1 << Int(sizeCode)
            let intValue = try readSignedInt(at: &index, size: byteCount)
            value = .integer(intValue)

        // Reals
        case Plist.Binary.Marker.real4:
            let bits = Self.readUnsignedInt(bytes, at: &index, size: 4)
            let floatValue = Float(bitPattern: UInt32(bits))
            value = .real(Double(floatValue))

        case Plist.Binary.Marker.real8:
            let bits = Self.readUnsignedInt(bytes, at: &index, size: 8)
            let doubleValue = Double(bitPattern: bits)
            value = .real(doubleValue)

        // Date
        case Plist.Binary.Marker.date:
            let bits = Self.readUnsignedInt(bytes, at: &index, size: 8)
            let dateValue = Double(bitPattern: bits)
            value = .date(dateValue)

        // Data (0x4n)
        case 0x40...0x4F:
            let length = try readLength(marker: marker, at: &index)
            let dataBytes = readBytes(at: &index, count: length)
            value = .data(dataBytes)

        // ASCII String (0x5n)
        case 0x50...0x5F:
            let length = try readLength(marker: marker, at: &index)
            let stringBytes = readBytes(at: &index, count: length)
            let string = String(decoding: stringBytes, as: UTF8.self)
            value = .string(string)

        // Unicode String (0x6n)
        case 0x60...0x6F:
            let length = try readLength(marker: marker, at: &index)
            // Length is in UTF-16 code units
            var utf16: [UInt16] = []
            utf16.reserveCapacity(length)
            for _ in 0..<length {
                let codeUnit = UInt16(Self.readUnsignedInt(bytes, at: &index, size: 2))
                utf16.append(codeUnit)
            }
            let string = String(decoding: utf16, as: UTF16.self)
            value = .string(string)

        // Array (0xAn)
        case 0xA0...0xAF:
            // Mark as being parsed to detect circular references
            parsedObjects[objectIndex] = .null

            let count = try readLength(marker: marker, at: &index)
            var elements: [Plist.Value] = []
            elements.reserveCapacity(count)

            for _ in 0..<count {
                let elementRef = Self.readUnsignedInt(bytes, at: &index, size: Int(trailer.objectRefSize))
                let element = try parseObject(at: elementRef)
                elements.append(element)
            }

            value = .array(elements)

        // Dictionary (0xDn)
        case 0xD0...0xDF:
            // Mark as being parsed to detect circular references
            parsedObjects[objectIndex] = .null

            let count = try readLength(marker: marker, at: &index)
            var members: [(key: String, value: Plist.Value)] = []
            members.reserveCapacity(count)

            // Read all keys first
            var keyRefs: [UInt64] = []
            keyRefs.reserveCapacity(count)
            for _ in 0..<count {
                let keyRef = Self.readUnsignedInt(bytes, at: &index, size: Int(trailer.objectRefSize))
                keyRefs.append(keyRef)
            }

            // Read all values
            var valueRefs: [UInt64] = []
            valueRefs.reserveCapacity(count)
            for _ in 0..<count {
                let valueRef = Self.readUnsignedInt(bytes, at: &index, size: Int(trailer.objectRefSize))
                valueRefs.append(valueRef)
            }

            // Parse keys and values
            for i in 0..<count {
                let keyValue = try parseObject(at: keyRefs[i])
                guard case let .string(key) = keyValue else {
                    throw .typeMismatch(expected: "string key", got: "non-string")
                }
                let entryValue = try parseObject(at: valueRefs[i])
                members.append((key: key, value: entryValue))
            }

            value = .dictionary(members)

        default:
            throw .invalidObjectType(marker)
        }

        parsedObjects[objectIndex] = value
        return value
    }
}

// MARK: - Reading Helpers

extension Plist.Binary.Context {
    func readLength(marker: UInt8, at index: inout Bytes.Index) throws(Plist.Error) -> Int {
        let lowNibble = Plist.Binary.Marker.lowNibble(marker)

        if lowNibble != Plist.Binary.Marker.extendedLength {
            return Int(lowNibble)
        }

        // Extended length: next byte is 0x1n where n indicates size power of 2
        guard index < bytes.endIndex else {
            throw .unexpectedEndOfData
        }

        let sizeMarker = bytes[index]
        index = bytes.index(after: index)

        guard Plist.Binary.Marker.highNibble(sizeMarker) == Plist.Binary.Marker.integerType else {
            throw .invalidObjectType(sizeMarker)
        }

        let sizeCode = Plist.Binary.Marker.lowNibble(sizeMarker)
        let byteCount = 1 << Int(sizeCode)
        let length = Self.readUnsignedInt(bytes, at: &index, size: byteCount)

        guard let intLength = Int(exactly: length) else {
            throw .integerOverflow
        }

        return intLength
    }

    func readSignedInt(at index: inout Bytes.Index, size: Int) throws(Plist.Error) -> Int64 {
        if size == 16 {
            // 16-byte integer: read high 8 bytes, then low 8 bytes
            let high = Self.readUnsignedInt(bytes, at: &index, size: 8)
            let low = Self.readUnsignedInt(bytes, at: &index, size: 8)

            // Check if it fits in Int64:
            // - If high is 0, it's a positive number that fits in UInt64
            // - If high is all 1s (0xFFFFFFFFFFFFFFFF), it's a negative number (sign extension)
            if high == 0 {
                // Positive number, check if low fits in Int64
                if low <= UInt64(Int64.max) {
                    return Int64(low)
                }
                // Treat as unsigned, return as signed (may wrap)
                return Int64(bitPattern: low)
            } else if high == UInt64.max {
                // Negative number with sign extension
                return Int64(bitPattern: low)
            } else {
                // True 128-bit value that doesn't fit - return low bytes
                // This loses precision but prevents crashing
                return Int64(bitPattern: low)
            }
        }

        guard size <= 8 else {
            throw .integerOverflow
        }

        let unsigned = Self.readUnsignedInt(bytes, at: &index, size: size)

        // Sign-extend if necessary
        if size < 8 {
            let signBit: UInt64 = 1 << (size * 8 - 1)
            if unsigned & signBit != 0 {
                // Negative number - sign extend
                let mask = UInt64.max << (size * 8)
                return Int64(bitPattern: unsigned | mask)
            }
        }

        return Int64(bitPattern: unsigned)
    }

    func readBytes(at index: inout Bytes.Index, count: Int) -> [UInt8] {
        var result: [UInt8] = []
        result.reserveCapacity(count)
        for _ in 0..<count {
            result.append(bytes[index])
            index = bytes.index(after: index)
        }
        return result
    }

    static func readUnsignedInt(_ bytes: Bytes, at index: inout Bytes.Index, size: Int) -> UInt64 {
        var result: UInt64 = 0
        for _ in 0..<size {
            result = (result << 8) | UInt64(bytes[index])
            index = bytes.index(after: index)
        }
        return result
    }
}
