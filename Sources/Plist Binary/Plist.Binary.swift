/// Plist.Binary
/// swift-plist
///
/// Binary plist parsing and serialization.

public import Plist_Core

extension Plist {
    /// Binary plist format namespace.
    ///
    /// Provides parsing and serialization for binary property lists.
    ///
    /// ## Overview
    ///
    /// Binary plists are used by Xcode artifacts (xcresult bundles, xcactivity logs)
    /// and offer better performance than XML plists for large data.
    ///
    /// ## File Structure
    ///
    /// ```
    /// ┌──────────────────────────────────────┐
    /// │ Header (8 bytes)                     │
    /// │   "bplist00" or "bplist01"          │
    /// ├──────────────────────────────────────┤
    /// │ Object Table                         │
    /// │   Variable-length encoded objects    │
    /// ├──────────────────────────────────────┤
    /// │ Offset Table                         │
    /// │   Offsets to each object             │
    /// ├──────────────────────────────────────┤
    /// │ Trailer (32 bytes)                   │
    /// │   Metadata and root object ref       │
    /// └──────────────────────────────────────┘
    /// ```
    public enum Binary {}
}
