extension Plist {

    public protocol Serializable: Sendable {

        static func serialize(_ value: Self) -> Plist

        static func deserialize(_ plist: Plist) throws(Plist.Error) -> Self
    }
}

extension Plist.Serializable {

    @inlinable
    public var plist: Plist {
        Self.serialize(self)
    }

    @inlinable
    public init(plist: Plist) throws(Plist.Error) {
        self = try Self.deserialize(plist)
    }
}

extension Plist: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: Plist) -> Plist {
        value
    }

    @inlinable
    public static func deserialize(_ plist: Plist) throws(Self.Error) -> Plist {
        plist
    }
}

extension String: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: String) -> Plist {
        .string(value)
    }

    @inlinable
    public static func deserialize(_ plist: Plist) throws(Plist.Error) -> String {
        guard case .string(let value) = plist.raw else {
            throw .typeMismatch(expected: "string", got: plist.typeName)
        }
        return value
    }
}

extension Int: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: Int) -> Plist {
        .integer(value)
    }

    @inlinable
    public static func deserialize(_ plist: Plist) throws(Plist.Error) -> Int {
        guard case .integer(let value) = plist.raw else {
            throw .typeMismatch(expected: "integer", got: plist.typeName)
        }
        guard let result = Int(exactly: value) else {
            throw .typeMismatch(expected: "integer (within Int range)", got: "integer (overflow)")
        }
        return result
    }
}

extension Int64: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: Int64) -> Plist {
        .integer(value)
    }

    @inlinable
    public static func deserialize(_ plist: Plist) throws(Plist.Error) -> Int64 {
        guard case .integer(let value) = plist.raw else {
            throw .typeMismatch(expected: "integer", got: plist.typeName)
        }
        return value
    }
}

extension Double: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: Double) -> Plist {
        .real(value)
    }

    @inlinable
    public static func deserialize(_ plist: Plist) throws(Plist.Error) -> Double {
        switch plist.raw {
        case .real(let value):
            return value

        case .integer(let value):
            return Double(value)

        default:
            throw .typeMismatch(expected: "real or integer", got: plist.typeName)
        }
    }
}

extension Bool: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: Bool) -> Plist {
        .bool(value)
    }

    @inlinable
    public static func deserialize(_ plist: Plist) throws(Plist.Error) -> Bool {
        guard case .bool(let value) = plist.raw else {
            throw .typeMismatch(expected: "bool", got: plist.typeName)
        }
        return value
    }
}

extension Array: Plist.Serializable where Element: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: [Element]) -> Plist {
        .array(value.map { Element.serialize($0) })
    }

    @inlinable
    public static func deserialize(_ plist: Plist) throws(Plist.Error) -> [Element] {
        guard let array = plist.array else {
            throw .typeMismatch(expected: "array", got: plist.typeName)
        }
        var result: [Element] = []
        result.reserveCapacity(array.count)
        for element in array {
            result.append(try Element.deserialize(element))
        }
        return result
    }
}

extension Dictionary: Plist.Serializable where Key == String, Value: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: [String: Value]) -> Plist {
        let members = value.map { ($0.key, Value.serialize($0.value)) }
        return .dictionary(members)
    }

    @inlinable
    public static func deserialize(_ plist: Plist) throws(Plist.Error) -> [String: Value] {
        guard let dict = plist.dictionary else {
            throw .typeMismatch(expected: "dictionary", got: plist.typeName)
        }
        var result: [String: Value] = [:]
        for member in dict {
            result[member.key] = try Value.deserialize(member.value)
        }
        return result
    }
}

extension Optional: Plist.Serializable where Wrapped: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: Wrapped?) -> Plist {
        guard let value else {
            return .null
        }
        return Wrapped.serialize(value)
    }

    @inlinable
    public static func deserialize(_ plist: Plist) throws(Plist.Error) -> Wrapped? {
        if plist.isNull {
            return nil
        }
        return try Wrapped.deserialize(plist)
    }
}

extension Plist {

    @usableFromInline
    internal var typeName: String {
        switch raw {
        case .string: return "string"
        case .integer: return "integer"
        case .real: return "real"
        case .bool: return "bool"
        case .data: return "data"
        case .date: return "date"
        case .array: return "array"
        case .dictionary: return "dictionary"
        case .null: return "null"
        }
    }
}
