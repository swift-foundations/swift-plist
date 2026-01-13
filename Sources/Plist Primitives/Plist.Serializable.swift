extension Plist {
    /// A type that can be serialized to and deserialized from plist format.
    public protocol Serializable: Sendable {
        /// Serializes this value to a plist representation.
        static func serialize(_ value: Self) -> Plist

        /// Deserializes a plist value to this type.
        static func deserialize(_ plist: Plist) throws(Plist.Error) -> Self
    }
}

// MARK: - Convenience Extensions

extension Plist.Serializable {
    /// The plist representation of this value.
    @inlinable
    public var plist: Plist {
        Self.serialize(self)
    }

    /// Creates an instance from a plist value.
    @inlinable
    public init(plist: Plist) throws(Plist.Error) {
        self = try Self.deserialize(plist)
    }
}

// MARK: - Plist Conformance

extension Plist: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: Plist) -> Plist {
        value
    }

    @inlinable
    public static func deserialize(_ plist: Plist) throws(Plist.Error) -> Plist {
        plist
    }
}

// MARK: - String Conformance

extension String: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: String) -> Plist {
        .string(value)
    }

    @inlinable
    public static func deserialize(_ plist: Plist) throws(Plist.Error) -> String {
        guard let value = plist.string else {
            throw .typeMismatch(expected: "string", got: plist.typeName)
        }
        return value
    }
}

// MARK: - Integer Conformances

extension Int: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: Int) -> Plist {
        .integer(value)
    }

    @inlinable
    public static func deserialize(_ plist: Plist) throws(Plist.Error) -> Int {
        guard let value = plist.int else {
            throw .typeMismatch(expected: "integer", got: plist.typeName)
        }
        return value
    }
}

extension Int64: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: Int64) -> Plist {
        .integer(value)
    }

    @inlinable
    public static func deserialize(_ plist: Plist) throws(Plist.Error) -> Int64 {
        guard let value = plist.integer else {
            throw .typeMismatch(expected: "integer", got: plist.typeName)
        }
        return value
    }
}

// MARK: - Double Conformance

extension Double: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: Double) -> Plist {
        .real(value)
    }

    @inlinable
    public static func deserialize(_ plist: Plist) throws(Plist.Error) -> Double {
        if let value = plist.real {
            return value
        }
        // Also accept integers as doubles
        if let value = plist.integer {
            return Double(value)
        }
        throw .typeMismatch(expected: "real or integer", got: plist.typeName)
    }
}

// MARK: - Bool Conformance

extension Bool: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: Bool) -> Plist {
        .bool(value)
    }

    @inlinable
    public static func deserialize(_ plist: Plist) throws(Plist.Error) -> Bool {
        guard let value = plist.bool else {
            throw .typeMismatch(expected: "bool", got: plist.typeName)
        }
        return value
    }
}

// MARK: - Array Conformance

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

// MARK: - Dictionary Conformance

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

// MARK: - Optional Conformance

extension Optional: Plist.Serializable where Wrapped: Plist.Serializable {
    @inlinable
    public static func serialize(_ value: Wrapped?) -> Plist {
        guard let value = value else {
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

// MARK: - Type Name Helper

extension Plist {
    /// The name of this plist value's type.
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
