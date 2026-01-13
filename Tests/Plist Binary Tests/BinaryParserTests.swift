import Testing
import Plist_Binary

@Suite("Plist Binary Parser Tests")
struct BinaryParserTests {
    @Test("Parse simple binary plist with string")
    func parseString() throws {
        // A minimal binary plist containing the string "hello"
        // Created by: plutil -convert binary1 -o - <(echo '<?xml version="1.0"?><plist><string>hello</string></plist>')
        let bytes: [UInt8] = [
            0x62, 0x70, 0x6C, 0x69, 0x73, 0x74, 0x30, 0x30, // "bplist00"
            0x55, 0x68, 0x65, 0x6C, 0x6C, 0x6F,             // string marker (0x55) + "hello"
            0x08,                                           // offset table (single entry = 8)
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // trailer: unused[5], sortVersion, offsetIntSize, objectRefSize
            0x01, 0x01,                                     // offsetIntSize=1, objectRefSize=1
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, // numObjects=1
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // topObject=0
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0E  // offsetTableOffset=14
        ]

        let plist = try Plist.Binary.parse(bytes)
        #expect(plist.string == "hello")
    }

    @Test("Invalid magic throws error")
    func invalidMagic() {
        let bytes: [UInt8] = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07]

        #expect(throws: Plist.Error.self) {
            try Plist.Binary.parse(bytes)
        }
    }

    @Test("Empty data throws error")
    func emptyData() {
        let bytes: [UInt8] = []

        #expect(throws: Plist.Error.self) {
            try Plist.Binary.parse(bytes)
        }
    }
}

@Suite("Plist Binary Serializer Tests")
struct BinarySerializerTests {
    @Test("Serialize and parse string")
    func roundTripString() throws {
        let original = Plist.string("Hello, Binary!")
        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(parsed.string == "Hello, Binary!")
    }

    @Test("Serialize and parse integer")
    func roundTripInteger() throws {
        let original = Plist.integer(12345)
        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(parsed.integer == 12345)
    }

    @Test("Serialize and parse negative integer")
    func roundTripNegativeInteger() throws {
        let original = Plist.integer(-9999)
        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(parsed.integer == -9999)
    }

    @Test("Serialize and parse real")
    func roundTripReal() throws {
        let original = Plist.real(3.14159)
        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(parsed.real == 3.14159)
    }

    @Test("Serialize and parse boolean")
    func roundTripBoolean() throws {
        let trueValue = Plist.bool(true)
        let falseValue = Plist.bool(false)

        let trueBytes = Plist.Binary.serialize(trueValue)
        let falseBytes = Plist.Binary.serialize(falseValue)

        let parsedTrue = try Plist.Binary.parse(trueBytes)
        let parsedFalse = try Plist.Binary.parse(falseBytes)

        #expect(parsedTrue.bool == true)
        #expect(parsedFalse.bool == false)
    }

    @Test("Serialize and parse data")
    func roundTripData() throws {
        let bytes: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05]
        let original = Plist.data(bytes)
        let serialized = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(serialized)

        #expect(parsed.data == bytes)
    }

    @Test("Serialize and parse array")
    func roundTripArray() throws {
        let original = Plist.array([
            .string("one"),
            .integer(2),
            .bool(true)
        ])
        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(parsed.isArray)
        #expect(parsed[0].string == "one")
        #expect(parsed[1].integer == 2)
        #expect(parsed[2].bool == true)
    }

    @Test("Serialize and parse dictionary")
    func roundTripDictionary() throws {
        let original = Plist.dictionary([
            ("name", .string("Alice")),
            ("score", .integer(100))
        ])
        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(parsed.isDictionary)
        #expect(parsed["name"].string == "Alice")
        #expect(parsed["score"].integer == 100)
    }

    @Test("Serialize and parse nested structures")
    func roundTripNested() throws {
        let original: Plist = [
            "user": [
                "name": "Bob",
                "tags": ["swift", "plist", "binary"]
            ],
            "version": 1
        ]

        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(parsed.user.name.string == "Bob")
        #expect(parsed.user.tags[0].string == "swift")
        #expect(parsed.user.tags[1].string == "plist")
        #expect(parsed.user.tags[2].string == "binary")
        #expect(parsed.version.integer == 1)
    }

    @Test("Binary starts with correct magic")
    func binaryMagic() {
        let plist = Plist.string("test")
        let bytes = Plist.Binary.serialize(plist)

        #expect(bytes.count >= 8)
        #expect(bytes[0] == 0x62) // 'b'
        #expect(bytes[1] == 0x70) // 'p'
        #expect(bytes[2] == 0x6C) // 'l'
        #expect(bytes[3] == 0x69) // 'i'
        #expect(bytes[4] == 0x73) // 's'
        #expect(bytes[5] == 0x74) // 't'
        #expect(bytes[6] == 0x30) // '0'
        #expect(bytes[7] == 0x30) // '0'
    }

    @Test("Unicode string round-trip")
    func unicodeRoundTrip() throws {
        let original = Plist.string("Hello, 世界! 🌍")
        let bytes = Plist.Binary.serialize(original)
        let parsed = try Plist.Binary.parse(bytes)

        #expect(parsed.string == "Hello, 世界! 🌍")
    }
}
