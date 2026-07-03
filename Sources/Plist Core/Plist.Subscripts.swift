// MARK: - Subscripts

extension Plist {
    /// Accesses a dictionary value by key.
    ///
    /// Returns `.null` if this is not a dictionary or if the key is not found.
    @inlinable
    public subscript(key: String) -> Plist {
        guard case .dictionary(let members) = raw else {
            return .null
        }
        for member in members {
            if member.key == key {
                return Plist(member.value)
            }
        }
        return .null
    }

    /// Accesses an array element by index.
    ///
    /// Returns `.null` if this is not an array or if the index is out of bounds.
    @inlinable
    public subscript(index: Int) -> Plist {
        guard case .array(let elements) = raw else {
            return .null
        }
        guard index >= 0, index < elements.count else {
            return .null
        }
        return Plist(elements[index])
    }

    /// Dynamic member lookup for dictionary access.
    ///
    /// Enables `plist.name` syntax as shorthand for `plist["name"]`.
    @inlinable
    public subscript(dynamicMember member: String) -> Plist {
        self[member]
    }
}
