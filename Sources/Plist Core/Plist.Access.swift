// MARK: - Collection and Special Type Access

extension Plist {
    /// Returns the data value, or `nil` if not data.
    @inlinable
    public var data: [UInt8]? {
        if case .data(let value) = raw { return value }
        return nil
    }

    /// Returns the date value as seconds since reference date, or `nil` if not a date.
    @inlinable
    public var date: Double? {
        if case .date(let value) = raw { return value }
        return nil
    }

    /// Returns the array elements as `[Plist]`, or `nil` if not an array.
    @inlinable
    public var array: [Plist]? {
        if case .array(let value) = raw {
            return value.map { Plist($0) }
        }
        return nil
    }

    /// Returns the dictionary members as key-value pairs, or `nil` if not a dictionary.
    @inlinable
    public var dictionary: [(key: String, value: Plist)]? {
        if case .dictionary(let value) = raw {
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
}
