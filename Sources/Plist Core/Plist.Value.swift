extension Plist {
    /// The underlying plist value representation.
    ///
    /// Represents any valid plist value: string, integer, real,
    /// boolean, data, date, array, or dictionary.
    public enum Value: Sendable, Hashable {
        /// A string value (`<string>` in XML).
        case string(String)

        /// A 64-bit signed integer (`<integer>` in XML).
        case integer(Int64)

        /// A 64-bit floating-point number (`<real>` in XML).
        case real(Double)

        /// A boolean value (`<true/>` or `<false/>` in XML).
        case bool(Bool)

        /// Raw binary data (`<data>` base64-encoded in XML).
        case data([UInt8])

        /// A date value (`<date>` ISO 8601 format in XML).
        ///
        /// Stored as seconds since the Apple reference date (2001-01-01 00:00:00 UTC).
        case date(Double)

        /// An ordered array (`<array>` in XML).
        case array([Self])

        /// A key-value dictionary (`<dict>` in XML).
        ///
        /// Keys are always strings. Order is preserved.
        case dictionary([(key: String, value: Self)])

        /// A null placeholder for missing or invalid values.
        ///
        /// This is not a valid plist type but is used internally for safe chaining.
        case null
    }
}

// MARK: - Hashable Conformance for Dictionary

extension Plist.Value {
    public static func == (lhs: Plist.Value, rhs: Plist.Value) -> Bool {
        switch (lhs, rhs) {
        case (.string(let l), .string(let r)):
            return l == r

        case (.integer(let l), .integer(let r)):
            return l == r

        case (.real(let l), .real(let r)):
            return l == r

        case (.bool(let l), .bool(let r)):
            return l == r

        case (.data(let l), .data(let r)):
            return l == r

        case (.date(let l), .date(let r)):
            return l == r

        case (.array(let l), .array(let r)):
            return l == r

        case (.dictionary(let l), .dictionary(let r)):
            guard l.count == r.count else { return false }
            for (index, lElement) in l.enumerated() {
                let rElement = r[index]
                guard lElement.key == rElement.key,
                    lElement.value == rElement.value
                else {
                    return false
                }
            }
            return true

        case (.null, .null):
            return true

        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .string(let value):
            hasher.combine(0)
            hasher.combine(value)

        case .integer(let value):
            hasher.combine(1)
            hasher.combine(value)

        case .real(let value):
            hasher.combine(2)
            hasher.combine(value)

        case .bool(let value):
            hasher.combine(3)
            hasher.combine(value)

        case .data(let value):
            hasher.combine(4)
            hasher.combine(value)

        case .date(let value):
            hasher.combine(5)
            hasher.combine(value)

        case .array(let value):
            hasher.combine(6)
            hasher.combine(value)

        case .dictionary(let value):
            hasher.combine(7)
            for element in value {
                hasher.combine(element.key)
                hasher.combine(element.value)
            }

        case .null:
            hasher.combine(8)
        }
    }
}

// MARK: - Literal Conformances on Plist.Value

extension Plist.Value: ExpressibleByNilLiteral {
    @inlinable
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension Plist.Value: ExpressibleByBooleanLiteral {
    @inlinable
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension Plist.Value: ExpressibleByIntegerLiteral {
    @inlinable
    public init(integerLiteral value: Int) {
        self = .integer(Int64(value))
    }
}

extension Plist.Value: ExpressibleByFloatLiteral {
    @inlinable
    public init(floatLiteral value: Double) {
        self = .real(value)
    }
}

extension Plist.Value: ExpressibleByStringLiteral {
    @inlinable
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension Plist.Value: ExpressibleByArrayLiteral {
    @inlinable
    public init(arrayLiteral elements: Plist.Value...) {
        self = .array(elements)
    }
}

extension Plist.Value: ExpressibleByDictionaryLiteral {
    @inlinable
    public init(dictionaryLiteral elements: (String, Plist.Value)...) {
        self = .dictionary(elements.map { ($0.0, $0.1) })
    }
}
