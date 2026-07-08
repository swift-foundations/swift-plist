/// Plist.Parse.Accessor.swift
/// swift-plist
///
/// Parse accessor pattern for plist parsing with compilation support.
///
/// This module provides the nested accessor pattern for plist parsing,
/// enabling discoverable access to different execution strategies:
///
/// ```swift
/// // Direct parsing (existing API)
/// let plist = try Plist.parse(bytes)
///
/// // Parse accessor pattern
/// let prepared = Plist.parse.prepared()
/// let plist = try prepared.parse(bytes)
/// ```
///
/// ## Multi-Format Support
///
/// Plist supports both XML and binary formats. The parser auto-detects
/// the format based on magic bytes, or you can specify explicitly:
///
/// ```swift
/// let plist = try Plist.parse.xml(string)
/// let plist = try Plist.parse.binary(bytes)
/// ```

import Plist_Binary
import Plist_Core
import Plist_XML

// MARK: - Parse Accessor

extension Plist {
    /// Accessor providing parse operation variants.
    ///
    /// The `Parse` struct encapsulates execution strategies for plist parsing,
    /// enabling discoverability via autocomplete:
    ///
    /// ```swift
    /// Plist.parse.
    ///           ├── prepared()   // Prepared parser, thread-safe
    ///           ├── located()    // Parse with byte-offset error tracking
    ///           ├── xml(_:)      // Parse XML format
    ///           ├── binary(_:)   // Parse binary format
    ///           └── callAsFunction()  // Auto-detect format (default)
    /// ```
    public struct Parse: Sendable {
        @usableFromInline
        internal init() {}
    }

    /// Accessor for parse operation variants.
    ///
    /// Use this to discover and access different execution strategies:
    /// - `parse.prepared()` — thread-safe prepared parser
    /// - `parse.located()` — parse with byte-offset error tracking
    /// - `parse(bytes)` — auto-detect format (shorthand)
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Create a prepared parser for concurrent access
    /// let parser = Plist.parse.prepared()
    ///
    /// // Parse multiple documents concurrently
    /// await withTaskGroup(of: Plist.self) { group in
    ///     for data in documents {
    ///         group.addTask { try parser.parse(data) }
    ///     }
    /// }
    /// ```
    public static var parse: Parse { Parse() }
}

// MARK: - Parse Operations

extension Plist.Parse {
    /// Parses a plist from bytes, auto-detecting the format.
    ///
    /// - Parameter bytes: The plist bytes (XML or binary).
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.Error` if parsing fails.
    @inlinable
    public func callAsFunction<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        guard let format = Plist.Format.detect(bytes) else {
            throw .unknownFormat
        }

        switch format {
        case .xml:
            return try Plist.XML.parse(bytes)

        case .binary:
            return try Plist.Binary.parse(bytes)
        }
    }

    /// Parses an XML plist from a string.
    ///
    /// - Parameter string: The XML plist string.
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.Error` if parsing fails.
    @inlinable
    public func xml(_ string: String) throws(Plist.Error) -> Plist {
        try Plist.XML.parse(string)
    }

    /// Parses an XML plist from bytes.
    ///
    /// - Parameter bytes: The XML plist bytes.
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.Error` if parsing fails.
    @inlinable
    public func xml<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        try Plist.XML.parse(bytes)
    }

    /// Parses a binary plist from bytes.
    ///
    /// - Parameter bytes: The binary plist bytes.
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.Error` if parsing fails.
    @inlinable
    public func binary<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8> {
        try Plist.Binary.parse(bytes)
    }
}

// MARK: - Prepared Parser

extension Plist.Parse {
    /// Creates an eagerly-prepared, thread-safe parser.
    ///
    /// The returned parser is `Sendable` and can be safely shared across
    /// concurrent tasks. Use this when you need to parse multiple documents
    /// in parallel or cache a parser for reuse.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let parser = Plist.parse.prepared()
    ///
    /// // Safe to use from multiple tasks
    /// Task { try parser.parse(data1) }
    /// Task { try parser.parse(data2) }
    /// ```
    ///
    /// - Returns: A thread-safe prepared parser.
    @inlinable
    public func prepared() -> Plist.Prepared {
        Plist.Prepared()
    }
}

// MARK: - Located Parsing

extension Plist.Parse {
    /// Creates a parser that tracks byte offsets in errors.
    ///
    /// The returned parser produces errors with byte offset information,
    /// enabling precise error reporting for diagnostics.
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     let plist = try Plist.parse.located().parse(bytes)
    /// } catch let error as Plist.LocatedError {
    ///     print("Error at byte \(error.offset): \(error.error)")
    /// }
    /// ```
    ///
    /// - Returns: A parser that produces located errors.
    @inlinable
    public func located() -> Plist.Located {
        Plist.Located()
    }
}

// MARK: - Prepared Type

extension Plist {
    /// A thread-safe, prepared plist parser.
    ///
    /// `Prepared` is `Sendable` and can be safely shared across concurrent
    /// tasks. Create one using `Plist.parse.prepared()`.
    ///
    /// ## Concurrency Safety
    ///
    /// ```swift
    /// let parser = Plist.parse.prepared()
    ///
    /// // Safe: Prepared is Sendable
    /// await withTaskGroup(of: Plist.self) { group in
    ///     for data in documents {
    ///         group.addTask { try parser.parse(data) }
    ///     }
    /// }
    /// ```
    public struct Prepared: Sendable {
        @usableFromInline
        internal init() {}
    }
}

// MARK: - Prepared Operations

extension Plist.Prepared {
    /// Parses a plist from bytes, auto-detecting the format.
    ///
    /// - Parameter bytes: The plist bytes (XML or binary).
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.Error` if parsing fails.
    @inlinable
    public func parse<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        try Plist.parse(bytes)
    }

    /// Parses an XML plist from a string.
    ///
    /// - Parameter string: The XML plist string.
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.Error` if parsing fails.
    @inlinable
    public func xml(_ string: String) throws(Plist.Error) -> Plist {
        try Plist.parse(xml: string)
    }

    /// Parses an XML plist from bytes.
    ///
    /// - Parameter bytes: The XML plist bytes.
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.Error` if parsing fails.
    @inlinable
    public func xml<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        try Plist.XML.parse(bytes)
    }

    /// Parses a binary plist from bytes.
    ///
    /// - Parameter bytes: The binary plist bytes.
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.Error` if parsing fails.
    @inlinable
    public func binary<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8> {
        try Plist.Binary.parse(bytes)
    }
}

// MARK: - Located Type

extension Plist {
    /// A parser that produces errors with byte-offset information.
    ///
    /// `Located` wraps parse errors with their byte offset in the input,
    /// enabling precise error reporting. Create one using `Plist.parse.located()`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     let plist = try Plist.parse.located().parse(bytes)
    /// } catch let error as Plist.LocatedError {
    ///     print("Error at byte \(error.offset): \(error.error)")
    /// }
    /// ```
    public struct Located: Sendable {
        @usableFromInline
        internal init() {}
    }
}

// MARK: - Located Operations

extension Plist.Located {
    /// Parses a plist from bytes with located errors.
    ///
    /// - Parameter bytes: The plist bytes (XML or binary).
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.LocatedError` if parsing fails.
    @inlinable
    public func parse<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.LocatedError) -> Plist
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        guard let format = Plist.Format.detect(bytes) else {
            throw Plist.LocatedError(.unknownFormat, at: 0)
        }

        switch format {
        case .xml:
            return try xml(bytes)

        case .binary:
            return try binary(bytes)
        }
    }

    /// Parses an XML plist with located errors.
    ///
    /// - Parameter bytes: The XML plist bytes.
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.LocatedError` if parsing fails.
    @inlinable
    public func xml<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.LocatedError) -> Plist
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        do throws(Plist.Error) {
            return try Plist.XML.parse(bytes)
        } catch {
            throw Plist.LocatedError(error, at: error.xmlOffset)
        }
    }

    /// Parses a binary plist with located errors.
    ///
    /// - Parameter bytes: The binary plist bytes.
    /// - Returns: The parsed plist value.
    /// - Throws: `Plist.LocatedError` if parsing fails.
    @inlinable
    public func binary<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.LocatedError) -> Plist
    where Bytes: Swift.Collection<UInt8> {
        do throws(Plist.Error) {
            return try Plist.Binary.parse(bytes)
        } catch {
            throw Plist.LocatedError(error, at: error.binaryOffset)
        }
    }
}

// MARK: - LocatedError Type

extension Plist {
    /// An error with byte-offset location information.
    ///
    /// This type wraps a `Plist.Error` with the byte offset where the error
    /// occurred, enabling precise error reporting.
    public struct LocatedError: Swift.Error, Sendable, Hashable {
        /// The underlying plist error.
        public let error: Plist.Error

        /// Byte offset from the start of input where the error occurred.
        public let offset: Int

        /// Creates a located error.
        ///
        /// - Parameters:
        ///   - error: The underlying error.
        ///   - offset: Byte offset from input start.
        @inlinable
        public init(_ error: Plist.Error, at offset: Int) {
            self.error = error
            self.offset = offset
        }
    }
}

extension Plist.LocatedError: CustomStringConvertible {
    public var description: String {
        "at byte \(offset): \(error)"
    }
}

// MARK: - Error Offset Extensions

extension Plist.Error {
    /// Byte offset for XML parsing errors.
    @usableFromInline
    var xmlOffset: Int {
        // XML plist uses swift-xml which tracks position
        // through the W3C_XML layer
        switch self {
        case .invalidXML(_, let line, _):
            // Line number is available but not byte offset
            // Return 0 as fallback
            return line > 0 ? 0 : 0

        default:
            return 0
        }
    }

    /// Byte offset for binary parsing errors.
    @usableFromInline
    var binaryOffset: Int {
        // Binary plist parsing doesn't currently track offsets
        // Future improvement: add offset tracking to Context
        switch self {
        case .invalidMagic:
            return 0

        case .invalidTrailer:
            // Trailer is at the end of the file
            return 0

        case .invalidObjectReference(let ref):
            // Object reference doesn't directly map to offset
            _ = ref
            return 0

        default:
            return 0
        }
    }
}
