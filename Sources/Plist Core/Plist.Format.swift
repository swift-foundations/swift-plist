extension Plist {
    /// The serialization format for a plist.
    public enum Format: Sendable, Hashable {
        /// XML plist format.
        case xml

        /// Binary plist format.
        case binary
    }
}

// MARK: - Format Detection

extension Plist.Format {
    /// Detects the format of a plist from its bytes.
    ///
    /// - Parameter bytes: The plist bytes.
    /// - Returns: The detected format, or `nil` if the format cannot be determined.
    @inlinable
    public static func detect<Bytes>(_ bytes: Bytes) -> Plist.Format?
    where Bytes: Swift.Collection<UInt8> {
        guard bytes.count >= 6 else { return nil }

        var iterator = bytes.makeIterator()
        let b0 = iterator.next()!
        let b1 = iterator.next()!
        let b2 = iterator.next()!
        let b3 = iterator.next()!
        let b4 = iterator.next()!
        let b5 = iterator.next()!

        // Binary plist: starts with "bplist"
        if b0 == 0x62,  // 'b'
            b1 == 0x70,  // 'p'
            b2 == 0x6C,  // 'l'
            b3 == 0x69,  // 'i'
            b4 == 0x73,  // 's'
            b5 == 0x74  // 't'
        {
            return .binary
        }

        // XML plist: starts with "<?xml" or "<plist" or whitespace followed by these
        // Skip leading whitespace
        var offset = 0
        for byte in bytes {
            if byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D {
                offset += 1
                continue
            }
            break
        }

        let remaining = bytes.dropFirst(offset)
        guard remaining.count >= 5 else { return nil }

        var remainingIterator = remaining.makeIterator()
        let r0 = remainingIterator.next()!
        let r1 = remainingIterator.next()!
        let r2 = remainingIterator.next()!
        let r3 = remainingIterator.next()!
        let r4 = remainingIterator.next()!

        // Check for "<?xml"
        if r0 == 0x3C,  // '<'
            r1 == 0x3F,  // '?'
            r2 == 0x78,  // 'x'
            r3 == 0x6D,  // 'm'
            r4 == 0x6C  // 'l'
        {
            return .xml
        }

        // Check for "<plis" (start of "<plist")
        if r0 == 0x3C,  // '<'
            r1 == 0x70,  // 'p'
            r2 == 0x6C,  // 'l'
            r3 == 0x69,  // 'i'
            r4 == 0x73  // 's'
        {
            return .xml
        }

        // Check for "<!DOC" (DOCTYPE declaration)
        if r0 == 0x3C,  // '<'
            r1 == 0x21,  // '!'
            r2 == 0x44,  // 'D'
            r3 == 0x4F,  // 'O'
            r4 == 0x43  // 'C'
        {
            return .xml
        }

        return nil
    }
}
