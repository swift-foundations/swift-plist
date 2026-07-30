/// A property list value.
///
/// `Plist` represents any valid plist value: string, integer, real,
/// boolean, data, date, array, or dictionary.
///
/// ## Construction
///
/// Use factory methods to construct plist values:
///
/// ```swift
/// let string = Plist.string("hello")
/// let number = Plist.integer(42)
/// let dict = Plist.dictionary([
///     ("name", .string("John")),
///     ("age", .integer(30))
/// ])
/// ```
///
/// Or use literal syntax:
///
/// ```swift
/// let plist: Plist = [
///     "name": "John",
///     "age": 30,
///     "active": true
/// ]
/// ```
///
/// ## Value Access
///
/// Extract values via initializers:
///
/// ```swift
/// String(plist.name)        // Optional("John")
/// Int(plist.age)            // Optional(30)
/// Bool(plist.active)        // Optional(true)
///
/// // Navigation
/// plist.user.name           // Plist value
/// plist["user"]["name"]     // Same via subscript
///
/// // Collection access
/// plist.array               // Optional([Plist])
/// plist.dictionary          // Optional([(key: String, value: Plist)])
/// ```
@dynamicMemberLookup
public struct Plist: Sendable, Hashable {
    @usableFromInline
    internal var raw: Value

    @inlinable
    public init(_ raw: Value) {
        self.raw = raw
    }
}

// MARK: - Value

extension Plist {
    /// The underlying plist value.
    @inlinable
    public var value: Value {
        raw
    }
}
