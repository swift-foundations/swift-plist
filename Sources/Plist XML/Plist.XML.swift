/// Plist.XML
/// swift-plist
///
/// XML plist parsing and serialization.

public import Plist_Core
import XML
import RFC_4648
import ISO_8601

extension Plist {
    /// XML plist format namespace.
    ///
    /// Provides parsing and serialization for XML property lists.
    ///
    /// ## Parsing
    ///
    /// ```swift
    /// let plist = try Plist.XML.parse(xmlString)
    /// print(plist.name.string)  // Access values
    /// ```
    ///
    /// ## Serialization
    ///
    /// ```swift
    /// let bytes = Plist.XML.serialize(plist, pretty: true)
    /// let string = String(decoding: bytes, as: UTF8.self)
    /// ```
    public enum XML {}
}
