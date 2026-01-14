import Plist_Primitives
import XML
import RFC_4648
import ISO_8601

// MARK: - Parsing

extension Plist.XML {
    /// Parses an XML plist from a string.
    ///
    /// - Parameter string: The XML plist string.
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.Error` if parsing fails.
    public static func parse(_ string: String) throws(Plist.Error) -> Plist {
        let doc: XML.Document
        do throws(XML.Error) {
            doc = try XML.parse(string)
        } catch {
            throw .invalidXML(message: "\(error)", line: 0, column: 0)
        }

        return try parseDocument(doc)
    }

    /// Parses an XML plist from bytes.
    ///
    /// - Parameter bytes: The UTF-8 encoded XML bytes.
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.Error` if parsing fails.
    public static func parse<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Collection<UInt8>, Bytes: Sendable {
        let doc: XML.Document
        do throws(XML.Error) {
            doc = try XML.parse(bytes)
        } catch {
            throw .invalidXML(message: "\(error)", line: 0, column: 0)
        }

        return try parseDocument(doc)
    }
}

// MARK: - Document Parsing

extension Plist.XML {
    private static func parseDocument(_ doc: XML.Document) throws(Plist.Error) -> Plist {
        let root = doc.root

        // The root element should be <plist>
        guard root.element.name == "plist" else {
            throw .unexpectedElement(expected: "plist", got: root.element.name)
        }

        // Get the content element (first child of plist)
        let children = root.children()
        guard let content = children.first else {
            throw .missingRequiredElement("plist content")
        }

        return try parseElement(content)
    }
}

// MARK: - Element Parsing

extension Plist.XML {
    private static func parseElement(_ element: XML) throws(Plist.Error) -> Plist {
        let name = element.element.name

        switch name {
        case "string":
            return Plist(.string(String(element)))

        case "integer":
            let text = String(element)
            guard !text.isEmpty, let value = Int64(text) else {
                throw .typeMismatch(expected: "integer", got: text.isEmpty ? "empty" : text)
            }
            return Plist(.integer(value))

        case "real":
            let text = String(element)
            guard !text.isEmpty, let value = Double(text) else {
                throw .typeMismatch(expected: "real", got: text.isEmpty ? "empty" : text)
            }
            return Plist(.real(value))

        case "true":
            return Plist(.bool(true))

        case "false":
            return Plist(.bool(false))

        case "data":
            let text = element.text.all
            // Strip whitespace from Base64 string
            let stripped = text.filter { !$0.isWhitespace }
            guard let bytes = RFC_4648.Base64.decode(stripped) else {
                throw .invalidBase64Data
            }
            return Plist(.data(bytes))

        case "date":
            let text = String(element)
            guard !text.isEmpty else {
                throw .invalidDateFormat("empty")
            }
            return try parseDate(text)

        case "array":
            var elements: [Plist.Value] = []
            for child in element.children() {
                let parsed = try parseElement(child)
                elements.append(parsed.value)
            }
            return Plist(.array(elements))

        case "dict":
            return try parseDictionary(element)

        default:
            throw .unexpectedElement(expected: "plist element", got: name)
        }
    }
}

// MARK: - Dictionary Parsing

extension Plist.XML {
    private static func parseDictionary(_ element: XML) throws(Plist.Error) -> Plist {
        var members: [(key: String, value: Plist.Value)] = []
        let children = element.children()

        var index = 0
        while index < children.count {
            let keyElement = children[index]

            // Expect <key> element
            guard keyElement.element.name == "key" else {
                throw .unexpectedElement(expected: "key", got: keyElement.element.name)
            }

            let key = String(keyElement)
            guard !key.isEmpty else {
                throw .missingRequiredElement("key text")
            }

            index += 1

            // Expect value element
            guard index < children.count else {
                throw .missingRequiredElement("value for key '\(key)'")
            }

            let valueElement = children[index]
            let parsedValue = try parseElement(valueElement)
            members.append((key: key, value: parsedValue.value))

            index += 1
        }

        return Plist(.dictionary(members))
    }
}

// MARK: - Date Parsing

extension Plist.XML {
    /// Apple reference date: 2001-01-01 00:00:00 UTC
    /// Difference from Unix epoch (1970-01-01): 978,307,200 seconds
    @usableFromInline
    static let appleReferenceEpochOffset: Int = 978_307_200

    private static func parseDate(_ text: String) throws(Plist.Error) -> Plist {
        // ISO 8601 format: 2024-01-15T12:30:00Z
        let dateTime: ISO_8601.DateTime
        do {
            dateTime = try ISO_8601.DateTime.Parser.parse(text)
        } catch {
            throw .invalidDateFormat(text)
        }

        // Convert from Unix epoch seconds to Apple reference date seconds
        let unixSeconds = dateTime.secondsSinceEpoch
        let nanoseconds = dateTime.nanoseconds
        let appleSeconds = Double(unixSeconds - appleReferenceEpochOffset)
            + Double(nanoseconds) / 1_000_000_000

        return Plist(.date(appleSeconds))
    }
}
