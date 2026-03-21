extension Plist {
    /// Errors that can occur during plist parsing and deserialization.
    public enum Error: Swift.Error, Sendable, Hashable {
        // MARK: - Format Detection

        /// The input format could not be determined.
        case unknownFormat

        /// The binary plist version is not supported.
        case unsupportedVersion(String)

        // MARK: - XML Parsing

        /// Invalid XML syntax.
        case invalidXML(message: String, line: Int, column: Int)

        /// Encountered an unexpected element.
        case unexpectedElement(expected: String, got: String)

        /// A required element is missing.
        case missingRequiredElement(String)

        /// Invalid Base64-encoded data.
        case invalidBase64Data

        /// Invalid date format.
        case invalidDateFormat(String)

        // MARK: - Binary Parsing

        /// The file does not start with a valid plist magic number.
        case invalidMagic

        /// The binary plist trailer is invalid.
        case invalidTrailer

        /// An object reference is out of bounds.
        case invalidObjectReference(UInt64)

        /// An unrecognized object type marker was encountered.
        case invalidObjectType(UInt8)

        /// An integer value overflowed during parsing.
        case integerOverflow

        /// A circular reference was detected.
        case circularReference

        /// The binary plist data is truncated or incomplete.
        case unexpectedEndOfData

        // MARK: - Deserialization

        /// Type mismatch during deserialization.
        case typeMismatch(expected: String, got: String)

        /// A required key is missing from a dictionary.
        case missingKey(String)
    }
}

// MARK: - CustomStringConvertible

extension Plist.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknownFormat:
            return "Unknown plist format"
        case let .unsupportedVersion(version):
            return "Unsupported plist version: \(version)"
        case let .invalidXML(message, line, column):
            return "Invalid XML at line \(line), column \(column): \(message)"
        case let .unexpectedElement(expected, got):
            return "Expected \(expected), got \(got)"
        case let .missingRequiredElement(name):
            return "Missing required element: \(name)"
        case .invalidBase64Data:
            return "Invalid Base64-encoded data"
        case let .invalidDateFormat(format):
            return "Invalid date format: \(format)"
        case .invalidMagic:
            return "Invalid binary plist magic number"
        case .invalidTrailer:
            return "Invalid binary plist trailer"
        case let .invalidObjectReference(ref):
            return "Invalid object reference: \(ref)"
        case let .invalidObjectType(marker):
            return "Invalid object type marker: 0x\(String(marker, radix: 16, uppercase: true))"
        case .integerOverflow:
            return "Integer overflow during parsing"
        case .circularReference:
            return "Circular reference detected"
        case .unexpectedEndOfData:
            return "Unexpected end of data"
        case let .typeMismatch(expected, got):
            return "Type mismatch: expected \(expected), got \(got)"
        case let .missingKey(key):
            return "Missing required key: \(key)"
        }
    }
}
