/// StreamTests.swift
/// swift-plist

import Testing
@testable import Plist

@Suite("Stream Tests")
struct StreamTests {

    // MARK: - ND Plist Streaming

    @Test("Parse ND plist stream")
    func parseNDPlist() async throws {
        let input = """
        <?xml version="1.0"?><plist version="1.0"><integer>1</integer></plist>
        <?xml version="1.0"?><plist version="1.0"><integer>2</integer></plist>
        <?xml version="1.0"?><plist version="1.0"><integer>3</integer></plist>
        """

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        var values: [Int] = []
        for await result in Plist.ND.stream(bytes) {
            let plist = try result.get()
            if case .integer(let value) = plist.value {
                values.append(Int(value))
            }
        }

        #expect(values == [1, 2, 3])
    }

    @Test("Skip empty lines in ND plist")
    func skipEmptyLines() async throws {
        let input = """
        <?xml version="1.0"?><plist version="1.0"><integer>1</integer></plist>

        <?xml version="1.0"?><plist version="1.0"><integer>2</integer></plist>

        """

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        var values: [Int] = []
        for await result in Plist.ND.stream(bytes) {
            let plist = try result.get()
            if case .integer(let value) = plist.value {
                values.append(Int(value))
            }
        }

        #expect(values == [1, 2])
    }

    @Test("Continue after malformed line")
    func continueAfterError() async {
        let input = """
        <?xml version="1.0"?><plist version="1.0"><integer>1</integer></plist>
        not valid plist
        <?xml version="1.0"?><plist version="1.0"><integer>3</integer></plist>
        """

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        var successes: [Int] = []
        var failures = 0

        for await result in Plist.ND.stream(bytes) {
            switch result {
            case .success(let plist):
                if case .integer(let value) = plist.value {
                    successes.append(Int(value))
                }
            case .failure:
                failures += 1
            }
        }

        #expect(successes == [1, 3])
        #expect(failures == 1)
    }

    @Test("Handle CRLF line endings")
    func handleCRLF() async throws {
        let input = "<?xml version=\"1.0\"?><plist version=\"1.0\"><integer>1</integer></plist>\r\n<?xml version=\"1.0\"?><plist version=\"1.0\"><integer>2</integer></plist>\r\n"

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        var values: [Int] = []
        for await result in Plist.ND.stream(bytes) {
            let plist = try result.get()
            if case .integer(let value) = plist.value {
                values.append(Int(value))
            }
        }

        #expect(values == [1, 2])
    }

    @Test("Parse without trailing newline")
    func noTrailingNewline() async throws {
        let input = "<?xml version=\"1.0\"?><plist version=\"1.0\"><integer>1</integer></plist>\n<?xml version=\"1.0\"?><plist version=\"1.0\"><integer>2</integer></plist>"

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        var values: [Int] = []
        for await result in Plist.ND.stream(bytes) {
            let plist = try result.get()
            if case .integer(let value) = plist.value {
                values.append(Int(value))
            }
        }

        #expect(values == [1, 2])
    }

    @Test("Reject binary plist in ND stream")
    func rejectBinaryPlist() async {
        // Binary plist magic: "bplist"
        let input = "bplist00\n"

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        var failures = 0
        for await result in Plist.ND.stream(bytes) {
            if case .failure = result {
                failures += 1
            }
        }

        #expect(failures == 1)
    }

    // MARK: - Single Document Async Parse

    @Test("Parse single document from async bytes")
    func parseSingleAsync() async throws {
        let input = "<?xml version=\"1.0\"?><plist version=\"1.0\"><dict><key>name</key><string>John</string><key>age</key><integer>30</integer></dict></plist>"

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        let plist = try await Plist.parse(collecting: bytes)

        // Verify it's a dictionary with expected keys
        if case .dictionary(let pairs) = plist.value {
            let keys = pairs.map(\.key)
            #expect(keys.contains("name"))
            #expect(keys.contains("age"))
        } else {
            Issue.record("Expected dictionary")
        }
    }

    @Test("Parse via accessor")
    func parseViaAccessor() async throws {
        let input = """
        <?xml version="1.0"?><plist version="1.0"><string>Hello</string></plist>
        """

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        let plist = try await Plist.parse.collecting(bytes)

        #expect(plist == Plist.string("Hello"))
    }

    @Test("Stream via accessor")
    func streamViaAccessor() async throws {
        let input = """
        <?xml version="1.0"?><plist version="1.0"><integer>1</integer></plist>
        <?xml version="1.0"?><plist version="1.0"><integer>2</integer></plist>
        """

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        var count = 0
        for await result in Plist.parse.stream(nd: bytes) {
            _ = try result.get()
            count += 1
        }

        #expect(count == 2)
    }

    @Test("Parse empty async stream")
    func parseEmptyAsync() async {
        let bytes = AsyncStream<UInt8> { continuation in
            continuation.finish()
        }

        do {
            _ = try await Plist.parse(collecting: bytes)
            Issue.record("Expected error for empty input")
        } catch {
            // Expected
        }
    }

    // MARK: - Plist.Serializable Async

    @Test("Deserialize from async bytes")
    func deserializeAsync() async throws {
        let input = """
        <?xml version="1.0"?><plist version="1.0"><integer>42</integer></plist>
        """

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        // Parse then deserialize to avoid XML/Plist ambiguity
        let plist = try await Plist.parse(collecting: bytes)
        let value = try Int.deserialize(plist)

        #expect(value == 42)
    }
}
