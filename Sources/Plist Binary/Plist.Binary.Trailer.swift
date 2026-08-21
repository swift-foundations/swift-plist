import Plist_Core

extension Plist.Binary {

    struct Trailer: Sendable {

        let unused: (UInt8, UInt8, UInt8, UInt8, UInt8)

        let sortVersion: UInt8

        let offsetIntSize: UInt8

        let objectRefSize: UInt8

        let numObjects: UInt64

        let topObject: UInt64

        let offsetTableOffset: UInt64
    }
}

extension Plist.Binary.Trailer {

    static let size: Int = 32

    static func parse<Bytes>(
        from bytes: Bytes
    ) throws(Plist.Error) -> Plist.Binary.Trailer
    where Bytes: Swift.Collection<UInt8> {
        guard bytes.count >= size else {
            throw .invalidTrailer
        }

        let trailerStart = bytes.index(bytes.endIndex, offsetBy: -size)
        var index = trailerStart

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

        let sortVersion = bytes[index]
        index = bytes.index(after: index)

        let offsetIntSize = bytes[index]
        index = bytes.index(after: index)

        let objectRefSize = bytes[index]
        index = bytes.index(after: index)

        guard (1...8).contains(offsetIntSize), (1...8).contains(objectRefSize) else {
            throw .invalidTrailer
        }

        let numObjects = readBigEndianUInt64(bytes, at: &index)

        let topObject = readBigEndianUInt64(bytes, at: &index)

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
    ) -> UInt64 where Bytes: Swift.Collection<UInt8> {
        var result: UInt64 = 0
        for _ in 0..<8 {
            result = (result << 8) | UInt64(bytes[index])
            index = bytes.index(after: index)
        }
        return result
    }
}
