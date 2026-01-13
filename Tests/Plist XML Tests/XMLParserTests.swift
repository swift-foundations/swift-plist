import Testing
import Plist_XML

@Suite("Plist XML Parser Tests")
struct XMLParserTests {
    @Test("Parse string element")
    func parseString() throws {
        let xml = """
        <?xml version="1.0"?>
        <plist version="1.0">
            <string>Hello, World!</string>
        </plist>
        """

        let plist = try Plist.XML.parse(xml)
        #expect(plist.string == "Hello, World!")
    }

    @Test("Parse integer element")
    func parseInteger() throws {
        let xml = """
        <?xml version="1.0"?>
        <plist version="1.0">
            <integer>42</integer>
        </plist>
        """

        let plist = try Plist.XML.parse(xml)
        #expect(plist.integer == 42)
    }

    @Test("Parse negative integer")
    func parseNegativeInteger() throws {
        let xml = """
        <?xml version="1.0"?>
        <plist version="1.0">
            <integer>-100</integer>
        </plist>
        """

        let plist = try Plist.XML.parse(xml)
        #expect(plist.integer == -100)
    }

    @Test("Parse real element")
    func parseReal() throws {
        let xml = """
        <?xml version="1.0"?>
        <plist version="1.0">
            <real>3.14159</real>
        </plist>
        """

        let plist = try Plist.XML.parse(xml)
        #expect(plist.real == 3.14159)
    }

    @Test("Parse true element")
    func parseTrue() throws {
        let xml = """
        <?xml version="1.0"?>
        <plist version="1.0">
            <true/>
        </plist>
        """

        let plist = try Plist.XML.parse(xml)
        #expect(plist.bool == true)
    }

    @Test("Parse false element")
    func parseFalse() throws {
        let xml = """
        <?xml version="1.0"?>
        <plist version="1.0">
            <false/>
        </plist>
        """

        let plist = try Plist.XML.parse(xml)
        #expect(plist.bool == false)
    }

    @Test("Parse data element")
    func parseData() throws {
        let xml = """
        <?xml version="1.0"?>
        <plist version="1.0">
            <data>SGVsbG8=</data>
        </plist>
        """

        let plist = try Plist.XML.parse(xml)
        #expect(plist.data == [0x48, 0x65, 0x6C, 0x6C, 0x6F]) // "Hello"
    }

    @Test("Parse date element")
    func parseDate() throws {
        let xml = """
        <?xml version="1.0"?>
        <plist version="1.0">
            <date>2024-01-15T12:30:00Z</date>
        </plist>
        """

        let plist = try Plist.XML.parse(xml)
        #expect(plist.isDate)
        // Date should be seconds since 2001-01-01
        #expect(plist.date != nil)
    }

    @Test("Parse array element")
    func parseArray() throws {
        let xml = """
        <?xml version="1.0"?>
        <plist version="1.0">
            <array>
                <string>one</string>
                <integer>2</integer>
                <true/>
            </array>
        </plist>
        """

        let plist = try Plist.XML.parse(xml)
        #expect(plist.isArray)
        #expect(plist.array?.count == 3)
        #expect(plist[0].string == "one")
        #expect(plist[1].integer == 2)
        #expect(plist[2].bool == true)
    }

    @Test("Parse dictionary element")
    func parseDict() throws {
        let xml = """
        <?xml version="1.0"?>
        <plist version="1.0">
            <dict>
                <key>name</key>
                <string>John</string>
                <key>age</key>
                <integer>30</integer>
            </dict>
        </plist>
        """

        let plist = try Plist.XML.parse(xml)
        #expect(plist.isDictionary)
        #expect(plist["name"].string == "John")
        #expect(plist["age"].integer == 30)
    }

    @Test("Parse nested structures")
    func parseNested() throws {
        let xml = """
        <?xml version="1.0"?>
        <plist version="1.0">
            <dict>
                <key>user</key>
                <dict>
                    <key>name</key>
                    <string>Alice</string>
                    <key>tags</key>
                    <array>
                        <string>swift</string>
                        <string>plist</string>
                    </array>
                </dict>
            </dict>
        </plist>
        """

        let plist = try Plist.XML.parse(xml)
        #expect(plist.user.name.string == "Alice")
        #expect(plist.user.tags[0].string == "swift")
        #expect(plist.user.tags[1].string == "plist")
    }
}

@Suite("Plist XML Serializer Tests")
struct XMLSerializerTests {
    @Test("Serialize string")
    func serializeString() {
        let plist = Plist.string("Hello")
        let bytes = Plist.XML.serialize(plist)
        let xml = String(decoding: bytes, as: UTF8.self)

        #expect(xml.contains("<string>Hello</string>"))
    }

    @Test("Serialize integer")
    func serializeInteger() {
        let plist = Plist.integer(42)
        let bytes = Plist.XML.serialize(plist)
        let xml = String(decoding: bytes, as: UTF8.self)

        #expect(xml.contains("<integer>42</integer>"))
    }

    @Test("Serialize boolean")
    func serializeBoolean() {
        let trueValue = Plist.bool(true)
        let falseValue = Plist.bool(false)

        let trueXml = String(decoding: Plist.XML.serialize(trueValue), as: UTF8.self)
        let falseXml = String(decoding: Plist.XML.serialize(falseValue), as: UTF8.self)

        #expect(trueXml.contains("<true/>") || trueXml.contains("<true></true>"))
        #expect(falseXml.contains("<false/>") || falseXml.contains("<false></false>"))
    }

    @Test("Serialize dictionary")
    func serializeDict() {
        let plist: Plist = [
            "name": "Bob",
            "age": 25
        ]

        let bytes = Plist.XML.serialize(plist)
        let xml = String(decoding: bytes, as: UTF8.self)

        #expect(xml.contains("<dict>"))
        #expect(xml.contains("<key>name</key>"))
        #expect(xml.contains("<string>Bob</string>"))
    }

    @Test("Round-trip parsing and serialization")
    func roundTrip() throws {
        let original: Plist = [
            "string": "hello",
            "number": 42,
            "real": 3.14,
            "bool": true,
            "array": [1, 2, 3]
        ]

        let bytes = Plist.XML.serialize(original)
        let parsed = try Plist.XML.parse(bytes)

        #expect(parsed["string"].string == "hello")
        #expect(parsed["number"].integer == 42)
        #expect(parsed["bool"].bool == true)
    }
}
