/// Plist.Stream.swift
/// swift-plist
///
/// Async Plist parsing support

public import Async

// MARK: - Async Parse

extension Plist {
    /// Parses a plist from an async byte sequence.
    ///
    /// Collects all bytes before parsing. Auto-detects XML or binary format.
    ///
    /// - Parameter bytes: The async sequence of bytes.
    /// - Returns: The parsed plist.
    /// - Throws: `Plist.Error` if parsing fails.
    @inlinable
    public static func parse<S: AsyncSequence & Sendable>(
        collecting bytes: S
    ) async throws(Self.Error) -> Plist
    where S.Element == UInt8 {
        var buffer: [UInt8] = []
        do {
            for try await byte in bytes {
                buffer.append(byte)
            }
        } catch {
            throw .unknownFormat
        }
        return try parse(buffer)
    }
}

// MARK: - Parse Accessor Async Extension

extension Plist.Parse {
    /// Parses a plist from an async byte sequence.
    ///
    /// Collects all bytes before parsing. Auto-detects XML or binary format.
    ///
    /// - Parameter bytes: The async sequence of bytes.
    /// - Returns: The parsed plist.
    /// - Throws: `Plist.Error` if parsing fails.
    @inlinable
    public func collecting<S: AsyncSequence & Sendable>(
        _ bytes: S
    ) async throws(Plist.Error) -> Plist
    where S.Element == UInt8 {
        try await Plist.parse(collecting: bytes)
    }
}

// MARK: - Serializable Async Support

extension Plist.Serializable {
    /// Creates a value from async plist bytes.
    @inlinable
    public init<S: AsyncSequence & Sendable>(
        collecting bytes: S
    ) async throws(Plist.Error)
    where S.Element == UInt8 {
        let plist = try await Plist.parse(collecting: bytes)
        self = try Self.deserialize(plist)
    }
}

// MARK: - Newline-Delimited Plist Streaming

extension Plist {
    /// Namespace for newline-delimited (ND) plist operations.
    ///
    /// ND Plist is a streaming format where each line contains a complete
    /// XML plist document. This enables processing large streams of plist
    /// data with minimal memory usage.
    ///
    /// ## Format
    ///
    /// Each line is a complete XML plist, separated by newlines:
    /// ```
    /// <?xml version="1.0"?><plist version="1.0"><string>Hello</string></plist>
    /// <?xml version="1.0"?><plist version="1.0"><integer>42</integer></plist>
    /// ```
    ///
    /// ## Limitations
    ///
    /// - Only XML format is supported (binary plist requires random access)
    /// - Each plist must be on a single line (no embedded newlines)
    ///
    /// ## Example
    ///
    /// ```swift
    /// for await result in Plist.ND.stream(bytes) {
    ///     switch result {
    ///     case .success(let plist):
    ///         process(plist)
    ///     case .failure(let error):
    ///         log(error)  // Stream continues after errors
    ///     }
    /// }
    /// ```
    public enum ND: Sendable {}
}

extension Plist.ND {
    /// Streams plist values from newline-delimited input.
    ///
    /// Parses each line as a complete XML plist. Empty lines are skipped.
    /// Errors on individual lines are returned as `.failure` results,
    /// allowing the stream to continue processing subsequent lines.
    ///
    /// - Parameter bytes: Async sequence of input bytes.
    /// - Returns: Stream of parse results (success or failure per line).
    @inlinable
    public static func stream<S: AsyncSequence & Sendable>(
        _ bytes: S
    ) -> Async.Stream<Result<Plist, Plist.Error>>
    where S.Element == UInt8 {
        Async.Stream {
            let state = State(bytes.makeAsyncIterator())
            return Async.Stream<Result<Plist, Plist.Error>>.Iterator {
                await state.next()
            }
        }
    }
}

extension Plist.ND {
    // WHY: Category D — structural Sendable workaround.
    // WHY: AsyncIteratorProtocol generic parameter blocks Sendable inference.
    // WHY: No caller invariant to uphold — data is structurally safe.
    // WHEN TO REMOVE: When compiler gains structural Sendable inference through
    // WHEN TO REMOVE: AsyncIteratorProtocol generic parameters.
    // TRACKING: unsafe-audit-findings.md Category D; SP-4.
    /// Internal state machine for ND plist parsing.
    @usableFromInline
    internal final class State<I: AsyncIteratorProtocol>: @unchecked Sendable
    where I.Element == UInt8 {
        @usableFromInline
        var iterator: I

        @usableFromInline
        var buffer: [UInt8] = []

        @usableFromInline
        var done = false

        @usableFromInline
        init(_ iterator: I) {
            self.iterator = iterator
        }
    }
}

// MARK: - State Machine Operations

extension Plist.ND.State {
    @usableFromInline
    func next() async -> Result<Plist, Plist.Error>? {
        if done { return nil }

        while true {
            let byte: UInt8?
            do {
                byte = try await iterator.next()
            } catch {
                done = true
                if buffer.isEmpty { return nil }
                defer { buffer.removeAll() }
                return parseLine()
            }

            guard let byte else {
                // End of input
                done = true
                if buffer.isEmpty { return nil }
                defer { buffer.removeAll() }
                return parseLine()
            }

            if byte == 0x0A {  // LF - newline
                if buffer.isEmpty { continue }  // Skip empty lines
                defer { buffer.removeAll(keepingCapacity: true) }
                return parseLine()
            }

            if byte == 0x0D { continue }  // Skip CR

            buffer.append(byte)
        }
    }

    @usableFromInline
    func parseLine() -> Result<Plist, Plist.Error> {
        // Check for binary plist magic (bplist)
        if buffer.count >= 6,
            buffer[0] == 0x62,  // 'b'
            buffer[1] == 0x70,  // 'p'
            buffer[2] == 0x6C,  // 'l'
            buffer[3] == 0x69,  // 'i'
            buffer[4] == 0x73,  // 's'
            buffer[5] == 0x74  // 't'
        {
            return .failure(.unknownFormat)
        }

        do throws(Plist.Error) {
            let plist = try Plist.parse.xml(buffer)
            return .success(plist)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Parse Accessor ND Extension

extension Plist.Parse {
    /// Streams plist values from newline-delimited input.
    ///
    /// Each line is parsed as a complete XML plist. Empty lines are skipped.
    /// Errors on individual lines are returned as `.failure` results.
    ///
    /// - Parameter bytes: Async sequence of input bytes.
    /// - Returns: Stream of parse results.
    @inlinable
    public func stream<S: AsyncSequence & Sendable>(
        nd bytes: S
    ) -> Async.Stream<Result<Plist, Plist.Error>>
    where S.Element == UInt8 {
        Plist.ND.stream(bytes)
    }
}
