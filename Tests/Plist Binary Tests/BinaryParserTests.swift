import Plist_Binary
import Testing

extension Plist.Binary {
@Suite("Plist Binary Parser Tests")
struct Parser {
    @Test
    func `Parse simple binary plist with string`() throws {
        // A minimal binary plist containing the string "hello"
        // Created by: plutil -convert binary1 -o - <(echo '<?xml version="1.0"?><plist><string>hello</string></plist>')
        let bytes: [UInt8] = [
            0x62, 0x70, 0x6C, 0x69, 0x73, 0x74, 0x30, 0x30,  // "bplist00"
            0x55, 0x68, 0x65, 0x6C, 0x6C, 0x6F,  // string marker (0x55) + "hello"
            0x08,  // offset table (single entry = 8)
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // trailer: unused[5], sortVersion, offsetIntSize, objectRefSize
            0x01, 0x01,  // offsetIntSize=1, objectRefSize=1
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,  // numObjects=1
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // topObject=0
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0E,  // offsetTableOffset=14
        ]

        let plist = try Plist.Binary.parse(bytes)
        #expect(String(plist) == "hello")
    }

    @Test
    func `Invalid magic throws error`() {
        let bytes: [UInt8] = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07]

        #expect(throws: Plist.Error.self) {
            try Plist.Binary.parse(bytes)
        }
    }

    @Test
    func `Empty data throws error`() {
        let bytes: [UInt8] = []

        #expect(throws: Plist.Error.self) {
            try Plist.Binary.parse(bytes)
        }
    }
}
}

extension Plist.Binary {
@Suite("Plist Binary Serializer Tests")
struct Serializer {
    @Test
    func `Serialize and parse string`() throws {
        let original = Plist.string("Hello, Binary!")
        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(String(parsed) == "Hello, Binary!")
    }

    @Test
    func `Serialize and parse integer`() throws {
        let original = Plist.integer(12345)
        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(Int64(parsed) == 12345)
    }

    @Test
    func `Serialize and parse negative integer`() throws {
        let original = Plist.integer(-9999)
        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(Int64(parsed) == -9999)
    }

    @Test
    func `Serialize and parse real`() throws {
        let original = Plist.real(3.14159)
        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(Double(parsed) == 3.14159)
    }

    @Test
    func `Serialize and parse boolean`() throws {
        let trueValue = Plist.bool(true)
        let falseValue = Plist.bool(false)

        let trueBytes = Plist.Binary.serialize(trueValue)
        let falseBytes = Plist.Binary.serialize(falseValue)

        let parsedTrue = try Plist.Binary.parse(trueBytes)
        let parsedFalse = try Plist.Binary.parse(falseBytes)

        #expect(Bool(parsedTrue) == true)
        #expect(Bool(parsedFalse) == false)
    }

    @Test
    func `Serialize and parse data`() throws {
        let bytes: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05]
        let original = Plist.data(bytes)
        let serialized = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(serialized)

        #expect(parsed.data == bytes)
    }

    @Test
    func `Serialize and parse array`() throws {
        let original = Plist.array([
            .string("one"),
            .integer(2),
            .bool(true),
        ])
        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(parsed.isArray)
        #expect(String(parsed[0]) == "one")
        #expect(Int64(parsed[1]) == 2)
        #expect(Bool(parsed[2]) == true)
    }

    @Test
    func `Serialize and parse dictionary`() throws {
        let original = Plist.dictionary([
            ("name", .string("Alice")),
            ("score", .integer(100)),
        ])
        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(parsed.isDictionary)
        #expect(String(parsed["name"]) == "Alice")
        #expect(Int64(parsed["score"]) == 100)
    }

    @Test
    func `Serialize and parse nested structures`() throws {
        let original: Plist = [
            "user": [
                "name": "Bob",
                "tags": ["swift", "plist", "binary"],
            ],
            "version": 1,
        ]

        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(String(parsed.user.name) == "Bob")
        #expect(String(parsed.user.tags[0]) == "swift")
        #expect(String(parsed.user.tags[1]) == "plist")
        #expect(String(parsed.user.tags[2]) == "binary")
        #expect(Int64(parsed.version) == 1)
    }

    @Test
    func `Binary starts with correct magic`() {
        let plist = Plist.string("test")
        let bytes = Plist.Binary.serialize(plist)

        #expect(bytes.count >= 8)
        #expect(bytes[0] == 0x62)  // 'b'
        #expect(bytes[1] == 0x70)  // 'p'
        #expect(bytes[2] == 0x6C)  // 'l'
        #expect(bytes[3] == 0x69)  // 'i'
        #expect(bytes[4] == 0x73)  // 's'
        #expect(bytes[5] == 0x74)  // 't'
        #expect(bytes[6] == 0x30)  // '0'
        #expect(bytes[7] == 0x30)  // '0'
    }

    @Test
    func `Unicode string round-trip`() throws {
        let original = Plist.string("Hello, 世界! 🌍")
        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(String(parsed) == "Hello, 世界! 🌍")
    }
}
}
