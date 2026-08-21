import Plist_Core

extension Plist.Binary {

    public static func parse<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8> {
        let context = try Context(bytes)
        return try context.parseRoot()
    }
}

extension Plist.Binary {

    final class Context<Bytes: Swift.Collection<UInt8>>: @unchecked Sendable {
        let bytes: Bytes
        let trailer: Trailer
        let offsets: [UInt64]
        var parsedObjects: [UInt64: Plist.Value] = [:]

        var objectsInProgress: Set<UInt64> = []

        init(_ bytes: Bytes) throws(Plist.Error) {
            self.bytes = bytes

            try Self.validateMagic(bytes)

            self.trailer = try Trailer.parse(from: bytes)

            self.offsets = try Self.parseOffsetTable(bytes, trailer: trailer)
        }
    }
}

extension Plist.Binary.Context {
    func parseRoot() throws(Plist.Error) -> Plist {
        let rootIndex = trailer.topObject
        let value = try parseObject(at: rootIndex)
        return Plist(value)
    }
}

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

        let v0 = bytes[index]
        index = bytes.index(after: index)
        let v1 = bytes[index]

        guard v0 == 0x30 else {
            throw .unsupportedVersion("\(v0)\(v1)")
        }

        guard v1 == 0x30 || v1 == 0x31 else {
            throw .unsupportedVersion("0\(Character(UnicodeScalar(v1)))")
        }
    }
}

extension Plist.Binary.Context {
    static func parseOffsetTable(
        _ bytes: Bytes,
        trailer: Plist.Binary.Trailer
    ) throws(Plist.Error) -> [UInt64] {
        let offsetIntSize = Int(trailer.offsetIntSize)

        guard let numObjects = Int(exactly: trailer.numObjects) else {
            throw .integerOverflow
        }
        guard let tableOffset = Int(exactly: trailer.offsetTableOffset) else {
            throw .integerOverflow
        }

        let (tableByteCount, sizeOverflow) = numObjects.multipliedReportingOverflow(
            by: offsetIntSize
        )
        guard !sizeOverflow else {
            throw .integerOverflow
        }
        let (tableEnd, endOverflow) = tableOffset.addingReportingOverflow(tableByteCount)
        guard !endOverflow else {
            throw .integerOverflow
        }

        guard tableEnd <= bytes.count else {
            throw .invalidTrailer
        }

        var offsets: [UInt64] = []
        offsets.reserveCapacity(numObjects)

        var index = bytes.index(bytes.startIndex, offsetBy: tableOffset)
        for _ in 0..<numObjects {
            let offset = try readUnsignedInt(bytes, at: &index, size: offsetIntSize)
            offsets.append(offset)
        }

        return offsets
    }
}

extension Plist.Binary.Context {
    func parseObject(at objectIndex: UInt64) throws(Plist.Error) -> Plist.Value {

        if let cached = parsedObjects[objectIndex] {
            return cached
        }

        guard objectsInProgress.insert(objectIndex).inserted else {
            throw .circularReference
        }
        defer { objectsInProgress.remove(objectIndex) }

        guard objectIndex < offsets.count else {
            throw .invalidObjectReference(objectIndex)
        }

        guard let offset = Int(exactly: offsets[Int(objectIndex)]) else {
            throw .integerOverflow
        }
        guard offset < bytes.count else {
            throw .invalidObjectReference(objectIndex)
        }

        var index = bytes.index(bytes.startIndex, offsetBy: offset)
        let marker = bytes[index]
        index = bytes.index(after: index)

        let value: Plist.Value

        switch marker {

        case Plist.Binary.Marker.null:
            value = .null

        case Plist.Binary.Marker.boolFalse:
            value = .bool(false)

        case Plist.Binary.Marker.boolTrue:
            value = .bool(true)

        case Plist.Binary.Marker.fill:
            value = .null

        case 0x10...0x1F:
            let sizeCode = Plist.Binary.Marker.lowNibble(marker)
            let byteCount = 1 << Int(sizeCode)
            let intValue = try readSignedInt(at: &index, size: byteCount)
            value = .integer(intValue)

        case Plist.Binary.Marker.real4:
            let bits = try Self.readUnsignedInt(bytes, at: &index, size: 4)
            let floatValue = Float(bitPattern: UInt32(bits))
            value = .real(Double(floatValue))

        case Plist.Binary.Marker.real8:
            let bits = try Self.readUnsignedInt(bytes, at: &index, size: 8)
            let doubleValue = Double(bitPattern: bits)
            value = .real(doubleValue)

        case Plist.Binary.Marker.date:
            let bits = try Self.readUnsignedInt(bytes, at: &index, size: 8)
            let dateValue = Double(bitPattern: bits)
            value = .date(dateValue)

        case 0x40...0x4F:
            let length = try readLength(marker: marker, at: &index)
            let dataBytes = try readBytes(at: &index, count: length)
            value = .data(dataBytes)

        case 0x50...0x5F:
            let length = try readLength(marker: marker, at: &index)
            let stringBytes = try readBytes(at: &index, count: length)
            let string = String(decoding: stringBytes, as: UTF8.self)
            value = .string(string)

        case 0x60...0x6F:
            let length = try readLength(marker: marker, at: &index)

            var utf16: [UInt16] = []
            utf16.reserveCapacity(length)
            for _ in 0..<length {
                let codeUnit = UInt16(try Self.readUnsignedInt(bytes, at: &index, size: 2))
                utf16.append(codeUnit)
            }
            let string = String(decoding: utf16, as: UTF16.self)
            value = .string(string)

        case 0xA0...0xAF:
            let count = try readLength(marker: marker, at: &index)
            var elements: [Plist.Value] = []
            elements.reserveCapacity(count)

            for _ in 0..<count {
                let elementRef = try Self.readUnsignedInt(
                    bytes,
                    at: &index,
                    size: Int(trailer.objectRefSize)
                )
                let element = try parseObject(at: elementRef)
                elements.append(element)
            }

            value = .array(elements)

        case 0xD0...0xDF:
            let count = try readLength(marker: marker, at: &index)
            var members: [(key: String, value: Plist.Value)] = []
            members.reserveCapacity(count)

            var keyRefs: [UInt64] = []
            keyRefs.reserveCapacity(count)
            for _ in 0..<count {
                let keyRef = try Self.readUnsignedInt(
                    bytes,
                    at: &index,
                    size: Int(trailer.objectRefSize)
                )
                keyRefs.append(keyRef)
            }

            var valueRefs: [UInt64] = []
            valueRefs.reserveCapacity(count)
            for _ in 0..<count {
                let valueRef = try Self.readUnsignedInt(
                    bytes,
                    at: &index,
                    size: Int(trailer.objectRefSize)
                )
                valueRefs.append(valueRef)
            }

            for i in 0..<count {
                let keyValue = try parseObject(at: keyRefs[i])
                guard case .string(let key) = keyValue else {
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

extension Plist.Binary.Context {
    func readLength(marker: UInt8, at index: inout Bytes.Index) throws(Plist.Error) -> Int {
        let lowNibble = Plist.Binary.Marker.lowNibble(marker)

        if lowNibble != Plist.Binary.Marker.extendedLength {
            return Int(lowNibble)
        }

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
        let length = try Self.readUnsignedInt(bytes, at: &index, size: byteCount)

        guard let intLength = Int(exactly: length) else {
            throw .integerOverflow
        }

        return intLength
    }

    func readSignedInt(at index: inout Bytes.Index, size: Int) throws(Plist.Error) -> Int64 {
        if size == 16 {

            let high = try Self.readUnsignedInt(bytes, at: &index, size: 8)
            let low = try Self.readUnsignedInt(bytes, at: &index, size: 8)

            let signExtension: UInt64 = (low & 0x8000_0000_0000_0000) != 0 ? .max : 0
            guard high == signExtension else {
                throw .integerOverflow
            }

            return Int64(bitPattern: low)
        }

        guard size <= 8 else {
            throw .integerOverflow
        }

        let unsigned = try Self.readUnsignedInt(bytes, at: &index, size: size)

        if size < 8 {
            let signBit: UInt64 = 1 << (size * 8 - 1)
            if unsigned & signBit != 0 {

                let mask = UInt64.max << (size * 8)
                return Int64(bitPattern: unsigned | mask)
            }
        }

        return Int64(bitPattern: unsigned)
    }

    func readBytes(at index: inout Bytes.Index, count: Int) throws(Plist.Error) -> [UInt8] {
        guard let end = bytes.index(index, offsetBy: count, limitedBy: bytes.endIndex) else {
            throw .unexpectedEndOfData
        }

        var result: [UInt8] = []
        result.reserveCapacity(count)
        while index < end {
            result.append(bytes[index])
            index = bytes.index(after: index)
        }
        index = end
        return result
    }

    static func readUnsignedInt(
        _ bytes: Bytes,
        at index: inout Bytes.Index,
        size: Int
    ) throws(Plist.Error) -> UInt64 {
        guard let end = bytes.index(index, offsetBy: size, limitedBy: bytes.endIndex) else {
            throw .unexpectedEndOfData
        }

        var result: UInt64 = 0
        while index < end {
            result = (result << 8) | UInt64(bytes[index])
            index = bytes.index(after: index)
        }
        return result
    }
}
