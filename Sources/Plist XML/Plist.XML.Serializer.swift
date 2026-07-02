import Plist_Core
import XML
internal import Byte_Primitive
import RFC_4648
import ISO_8601

// MARK: - Serialization

extension Plist.XML {
    /// Serializes a plist to XML bytes.
    ///
    /// - Parameters:
    ///   - plist: The plist value to serialize.
    ///   - pretty: Whether to format with indentation.
    /// - Returns: The UTF-8 encoded XML bytes.
    public static func serialize(_ plist: Plist, pretty: Bool = false) -> [UInt8] {
        let rootElement = serializeValue(plist.value)
        let plistElement = XML.element("plist", children: [rootElement])

        // Create document with XML declaration
        let doc = XML.Document(
            version: .v1_0,
            encoding: "UTF-8",
            root: plistElement
        )

        return doc.serialize.bytes(pretty: pretty)
    }

    /// Serializes a plist to an XML string.
    ///
    /// - Parameters:
    ///   - plist: The plist value to serialize.
    ///   - pretty: Whether to format with indentation.
    /// - Returns: The XML string.
    public static func serializeString(_ plist: Plist, pretty: Bool = false) -> String {
        String(decoding: serialize(plist, pretty: pretty), as: UTF8.self)
    }
}

// MARK: - Value Serialization

extension Plist.XML {
    private static func serializeValue(_ value: Plist.Value) -> XML {
        switch value {
        case let .string(text):
            return XML.element("string", text: text)

        case let .integer(number):
            return XML.element("integer", text: String(number))

        case let .real(number):
            // Format real numbers without unnecessary precision
            let text: String
            if number.truncatingRemainder(dividingBy: 1) == 0 {
                // Whole number - still show decimal point for plist convention
                let intPart = Int(number)
                text = "\(intPart).0"
            } else {
                text = String(number)
            }
            return XML.element("real", text: text)

        case let .bool(flag):
            return flag ? XML.element("true") : XML.element("false")

        case let .data(bytes):
            let base64 = RFC_4648.Base64.encode(bytes.lazy.map(Byte.init), padding: true)
            let base64String = String(decoding: base64.lazy.map(\.underlying), as: UTF8.self)
            return XML.element("data", text: base64String)

        case let .date(secondsSinceRef):
            let text = formatDate(secondsSinceRef)
            return XML.element("date", text: text)

        case let .array(elements):
            let children = elements.map { serializeValue($0) }
            return XML.element("array", children: children)

        case let .dictionary(members):
            var children: [XML] = []
            for member in members {
                children.append(XML.element("key", text: member.key))
                children.append(serializeValue(member.value))
            }
            return XML.element("dict", children: children)

        case .null:
            // Null is not a valid plist type, serialize as empty string
            return XML.element("string", text: "")
        }
    }
}

// MARK: - Date Formatting

extension Plist.XML {
    private static func formatDate(_ secondsSinceRef: Double) -> String {
        // Convert Apple reference date to Unix epoch
        let unixSeconds = Int(secondsSinceRef) + appleReferenceEpochOffset

        // Extract nanoseconds from fractional part
        let fractionalPart = secondsSinceRef - Double(Int(secondsSinceRef))
        let nanoseconds = Int(fractionalPart * 1_000_000_000)

        // Create DateTime and format it
        guard let dateTime = try? ISO_8601.DateTime(
            secondsSinceEpoch: unixSeconds,
            nanoseconds: nanoseconds,
            timezoneOffsetSeconds: 0
        ) else {
            // Fallback: return a basic representation
            return "2001-01-01T00:00:00Z"
        }

        return ISO_8601.DateTime.Formatter.format(dateTime)
    }
}
