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

        case .unsupportedVersion(let version):
            return "Unsupported plist version: \(version)"

        case .invalidXML(let message, let line, let column):
            return "Invalid XML at line \(line), column \(column): \(message)"

        case .unexpectedElement(let expected, let got):
            return "Expected \(expected), got \(got)"

        case .missingRequiredElement(let name):
            return "Missing required element: \(name)"

        case .invalidBase64Data:
            return "Invalid Base64-encoded data"

        case .invalidDateFormat(let format):
            return "Invalid date format: \(format)"

        case .invalidMagic:
            return "Invalid binary plist magic number"

        case .invalidTrailer:
            return "Invalid binary plist trailer"

        case .invalidObjectReference(let ref):
            return "Invalid object reference: \(ref)"

        case .invalidObjectType(let marker):
            return "Invalid object type marker: 0x\(String(marker, radix: 16, uppercase: true))"

        case .integerOverflow:
            return "Integer overflow during parsing"

        case .circularReference:
            return "Circular reference detected"

        case .unexpectedEndOfData:
            return "Unexpected end of data"

        case .typeMismatch(let expected, let got):
            return "Type mismatch: expected \(expected), got \(got)"

        case .missingKey(let key):
            return "Missing required key: \(key)"
        }
    }
}
