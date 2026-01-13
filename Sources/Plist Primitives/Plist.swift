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
/// Access values through typed properties or subscripts:
///
/// ```swift
/// let name = plist.name.string       // Optional String
/// let age = plist["age"].int         // Optional Int
/// let missing = plist.missing        // Returns null plist
/// ```
@dynamicMemberLookup
public struct Plist: Sendable, Hashable {
    /// The plist value type.
    ///
    /// Represents any valid plist value: string, integer, real,
    /// boolean, data, date, array, or dictionary.
    public typealias Value = _Raw

    @usableFromInline
    internal var raw: _Raw

    @inlinable
    public init(_ raw: _Raw) {
        self.raw = raw
    }

    /// The underlying plist value.
    @inlinable
    public var value: Value {
        raw
    }
}
