// MARK: - Type Checking

extension Plist {
    /// Returns `true` if this is a string value.
    @inlinable
    public var isString: Bool {
        if case .string = raw { return true }
        return false
    }

    /// Returns `true` if this is an integer value.
    @inlinable
    public var isInteger: Bool {
        if case .integer = raw { return true }
        return false
    }

    /// Returns `true` if this is a real (floating-point) value.
    @inlinable
    public var isReal: Bool {
        if case .real = raw { return true }
        return false
    }

    /// Returns `true` if this is a boolean value.
    @inlinable
    public var isBool: Bool {
        if case .bool = raw { return true }
        return false
    }

    /// Returns `true` if this is a data value.
    @inlinable
    public var isData: Bool {
        if case .data = raw { return true }
        return false
    }

    /// Returns `true` if this is a date value.
    @inlinable
    public var isDate: Bool {
        if case .date = raw { return true }
        return false
    }

    /// Returns `true` if this is an array value.
    @inlinable
    public var isArray: Bool {
        if case .array = raw { return true }
        return false
    }

    /// Returns `true` if this is a dictionary value.
    @inlinable
    public var isDictionary: Bool {
        if case .dictionary = raw { return true }
        return false
    }

    /// Returns `true` if this is a null placeholder.
    @inlinable
    public var isNull: Bool {
        if case .null = raw { return true }
        return false
    }
}
