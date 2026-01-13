import Testing
import Plist_Binary
import Darwin

// MARK: - File Reading Helper

private func readFile(_ path: String) -> [UInt8]? {
    guard let file = fopen(path, "rb") else {
        return nil
    }
    defer { fclose(file) }

    fseek(file, 0, SEEK_END)
    let size = ftell(file)
    fseek(file, 0, SEEK_SET)

    guard size > 0 else { return nil }

    var buffer = [UInt8](repeating: 0, count: size)
    let bytesRead = fread(&buffer, 1, size, file)
    guard bytesRead == size else { return nil }

    return buffer
}

// MARK: - Tests

@Suite("Real Binary Plist Tests")
struct RealBinaryPlistTests {
    @Test("Parse com.apple.finder.plist")
    func parseFinderPlist() throws {
        let path = "/Users/coen/Library/Preferences/com.apple.finder.plist"

        guard let bytes = readFile(path) else {
            Issue.record("Could not read \(path) - file may not exist")
            return
        }

        // Verify it's a binary plist
        let format = Plist.Format.detect(bytes)
        #expect(format == .binary, "Expected binary plist format")

        // Parse it
        let plist = try Plist.Binary.parse(bytes)

        // Finder prefs are always a dictionary
        #expect(plist.dictionary != nil, "Expected dictionary at root")

        // Should have many keys
        if let dict = plist.dictionary {
            #expect(dict.count > 10, "Expected many keys in Finder preferences")
        }
    }

    @Test("Parse com.apple.dock.plist")
    func parseDockPlist() throws {
        let path = "/Users/coen/Library/Preferences/com.apple.dock.plist"

        guard let bytes = readFile(path) else {
            Issue.record("Could not read \(path) - file may not exist")
            return
        }

        let format = Plist.Format.detect(bytes)
        #expect(format == .binary, "Expected binary plist format")

        let plist = try Plist.Binary.parse(bytes)

        #expect(plist.dictionary != nil, "Expected dictionary at root")

        // Check for known dock keys
        if let dict = plist.dictionary {
            let keys = dict.map { $0.key }
            // Dock plist typically has these keys
            let hasTypicalKey = keys.contains("autohide") ||
                               keys.contains("tilesize") ||
                               keys.contains("persistent-apps")
            #expect(hasTypicalKey, "Expected typical dock preference keys")
        }
    }

    @Test("Parse any available binary plist")
    func parseAnyBinaryPlist() throws {
        // Try several common binary plist locations
        let candidates = [
            "/Users/coen/Library/Preferences/com.apple.finder.plist",
            "/Users/coen/Library/Preferences/com.apple.dock.plist",
            "/Library/Preferences/com.apple.loginwindow.plist",
        ]

        var parsed = false

        for path in candidates {
            guard let bytes = readFile(path) else { continue }

            let format = Plist.Format.detect(bytes)
            guard format == .binary else { continue }

            let plist = try Plist.Binary.parse(bytes)
            #expect(plist.dictionary != nil || plist.array != nil,
                   "Expected dictionary or array at root")
            parsed = true
            break
        }

        #expect(parsed, "Could not find any binary plist to test")
    }
}
