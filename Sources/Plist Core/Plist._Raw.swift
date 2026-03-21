/// The underlying plist value representation.
///
/// Use `Plist.Value` instead of this type directly.
public enum _Raw: Sendable, Hashable {
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
    case array([_Raw])

    /// A key-value dictionary (`<dict>` in XML).
    ///
    /// Keys are always strings. Order is preserved.
    case dictionary([(key: String, value: _Raw)])

    /// A null placeholder for missing or invalid values.
    ///
    /// This is not a valid plist type but is used internally for safe chaining.
    case null
}

// MARK: - Hashable Conformance for Dictionary

extension _Raw {
    public static func == (lhs: _Raw, rhs: _Raw) -> Bool {
        switch (lhs, rhs) {
        case let (.string(l), .string(r)):
            return l == r
        case let (.integer(l), .integer(r)):
            return l == r
        case let (.real(l), .real(r)):
            return l == r
        case let (.bool(l), .bool(r)):
            return l == r
        case let (.data(l), .data(r)):
            return l == r
        case let (.date(l), .date(r)):
            return l == r
        case let (.array(l), .array(r)):
            return l == r
        case let (.dictionary(l), .dictionary(r)):
            guard l.count == r.count else { return false }
            for (index, lElement) in l.enumerated() {
                let rElement = r[index]
                guard lElement.key == rElement.key,
                      lElement.value == rElement.value else {
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
        case let .string(value):
            hasher.combine(0)
            hasher.combine(value)
        case let .integer(value):
            hasher.combine(1)
            hasher.combine(value)
        case let .real(value):
            hasher.combine(2)
            hasher.combine(value)
        case let .bool(value):
            hasher.combine(3)
            hasher.combine(value)
        case let .data(value):
            hasher.combine(4)
            hasher.combine(value)
        case let .date(value):
            hasher.combine(5)
            hasher.combine(value)
        case let .array(value):
            hasher.combine(6)
            hasher.combine(value)
        case let .dictionary(value):
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

// MARK: - Literal Conformances on _Raw

extension _Raw: ExpressibleByNilLiteral {
    @inlinable
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension _Raw: ExpressibleByBooleanLiteral {
    @inlinable
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension _Raw: ExpressibleByIntegerLiteral {
    @inlinable
    public init(integerLiteral value: Int) {
        self = .integer(Int64(value))
    }
}

extension _Raw: ExpressibleByFloatLiteral {
    @inlinable
    public init(floatLiteral value: Double) {
        self = .real(value)
    }
}

extension _Raw: ExpressibleByStringLiteral {
    @inlinable
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension _Raw: ExpressibleByArrayLiteral {
    @inlinable
    public init(arrayLiteral elements: _Raw...) {
        self = .array(elements)
    }
}

extension _Raw: ExpressibleByDictionaryLiteral {
    @inlinable
    public init(dictionaryLiteral elements: (String, _Raw)...) {
        self = .dictionary(elements.map { ($0.0, $0.1) })
    }
}
