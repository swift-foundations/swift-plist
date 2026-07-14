// These suites parse real macOS system plists (Finder/Dock/loginwindow
// preferences under `~/Library/Preferences`) — content and paths that only
// exist on Darwin, so the whole file is gated rather than swapped onto a
// cross-platform file-reading primitive.
#if canImport(Darwin)
    import Darwin
    import Plist_Binary
    import Testing

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

    /// Preferences path for the current user, when resolvable.
    ///
    /// These suites parse real system plists opportunistically: on machines
    /// without the expected files (CI runners, fresh installs) the tests skip
    /// quietly rather than fail — a missing local preferences file is not a
    /// parser defect.
    private func preferencesPath(_ name: String) -> String? {
        guard let home = getenv("HOME").map({ String(cString: $0) }), !home.isEmpty else {
            return nil
        }
        return home + "/Library/Preferences/" + name
    }

    // MARK: - Tests

    extension Plist.Binary {
        @Suite("Real Binary Plist Tests")
        struct Test {
            @Test
            func `Parse com.apple.finder.plist`() throws {
                guard let path = preferencesPath("com.apple.finder.plist"),
                    let bytes = readFile(path)
                else { return }

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

            @Test
            func `Parse com.apple.dock.plist`() throws {
                guard let path = preferencesPath("com.apple.dock.plist"),
                    let bytes = readFile(path)
                else { return }

                let format = Plist.Format.detect(bytes)
                #expect(format == .binary, "Expected binary plist format")

                let plist = try Plist.Binary.parse(bytes)

                #expect(plist.dictionary != nil, "Expected dictionary at root")

                // Check for known dock keys
                if let dict = plist.dictionary {
                    let keys = dict.map { $0.key }
                    // Dock plist typically has these keys
                    let hasTypicalKey = keys.contains("autohide") || keys.contains("tilesize") || keys.contains("persistent-apps")
                    #expect(hasTypicalKey, "Expected typical dock preference keys")
                }
            }

            @Test
            func `Parse any available binary plist`() throws {
                // Try several common binary plist locations; absence of all of
                // them (CI runners, fresh installs) is a quiet skip, not a failure.
                let candidates = [
                    preferencesPath("com.apple.finder.plist"),
                    preferencesPath("com.apple.dock.plist"),
                    "/Library/Preferences/com.apple.loginwindow.plist",
                ].compactMap { $0 }

                for path in candidates {
                    guard let bytes = readFile(path) else { continue }

                    let format = Plist.Format.detect(bytes)
                    guard format == .binary else { continue }

                    let plist = try Plist.Binary.parse(bytes)
                    #expect(
                        plist.dictionary != nil || plist.array != nil,
                        "Expected dictionary or array at root"
                    )
                    break
                }
            }
        }
    }
#endif  // canImport(Darwin)
