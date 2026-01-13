// MARK: - Value Access

extension Plist {
    /// Returns the string value, or `nil` if not a string.
    @inlinable
    public var string: String? {
        if case let .string(value) = raw { return value }
        return nil
    }

    /// Returns the integer value as `Int64`, or `nil` if not an integer.
    @inlinable
    public var integer: Int64? {
        if case let .integer(value) = raw { return value }
        return nil
    }

    /// Returns the integer value as `Int`, or `nil` if not an integer
    /// or if the value overflows `Int`.
    @inlinable
    public var int: Int? {
        guard let value = integer else { return nil }
        return Int(exactly: value)
    }

    /// Returns the real value, or `nil` if not a real.
    @inlinable
    public var real: Double? {
        if case let .real(value) = raw { return value }
        return nil
    }

    /// Returns the boolean value, or `nil` if not a boolean.
    @inlinable
    public var bool: Bool? {
        if case let .bool(value) = raw { return value }
        return nil
    }

    /// Returns the data value, or `nil` if not data.
    @inlinable
    public var data: [UInt8]? {
        if case let .data(value) = raw { return value }
        return nil
    }

    /// Returns the date value as seconds since reference date, or `nil` if not a date.
    @inlinable
    public var date: Double? {
        if case let .date(value) = raw { return value }
        return nil
    }

    /// Returns the array elements as `[Plist]`, or `nil` if not an array.
    @inlinable
    public var array: [Plist]? {
        if case let .array(value) = raw {
            return value.map { Plist($0) }
        }
        return nil
    }

    /// Returns the dictionary members as key-value pairs, or `nil` if not a dictionary.
    @inlinable
    public var dictionary: [(key: String, value: Plist)]? {
        if case let .dictionary(value) = raw {
            return value.map { (key: $0.key, value: Plist($0.value)) }
        }
        return nil
    }

    /// Returns the dictionary as a `[String: Plist]` map, or `nil` if not a dictionary.
    ///
    /// Note: If there are duplicate keys, later values overwrite earlier ones.
    @inlinable
    public var dictionaryValue: [String: Plist]? {
        guard let members = dictionary else { return nil }
        var result: [String: Plist] = [:]
        for member in members {
            result[member.key] = member.value
        }
        return result
    }

    /// Returns a numeric value as `Double`, converting integers if needed.
    ///
    /// Returns `nil` if not an integer or real.
    @inlinable
    public var number: Double? {
        switch raw {
        case let .real(value):
            return value
        case let .integer(value):
            return Double(value)
        default:
            return nil
        }
    }
}
