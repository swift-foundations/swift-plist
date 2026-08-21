extension Plist {

    public enum Value: Sendable, Hashable {

        case string(String)

        case integer(Int64)

        case real(Double)

        case bool(Bool)

        case data([UInt8])

        case date(Double)

        case array([Self])

        case dictionary([(key: String, value: Self)])

        case null
    }
}

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
