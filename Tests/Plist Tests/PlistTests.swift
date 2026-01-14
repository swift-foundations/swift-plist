import Testing
import Plist

@Suite("Plist Value Tests")
struct PlistValueTests {
    @Test("String creation and access")
    func stringValue() {
        let plist = Plist.string("hello")
        #expect(plist.isString)
        #expect(String(plist) == "hello")
        #expect(!plist.isInteger)
        #expect(Int64(plist) == nil)
    }

    @Test("Integer creation and access")
    func integerValue() {
        let plist = Plist.integer(42)
        #expect(plist.isInteger)
        #expect(Int64(plist) == 42)
        #expect(Int(plist) == 42)
        #expect(!plist.isString)
    }

    @Test("Real creation and access")
    func realValue() {
        let plist = Plist.real(3.14)
        #expect(plist.isReal)
        #expect(Double(plist) == 3.14)
    }

    @Test("Bool creation and access")
    func boolValue() {
        let trueValue = Plist.bool(true)
        let falseValue = Plist.bool(false)

        #expect(trueValue.isBool)
        #expect(Bool(trueValue) == true)
        #expect(Bool(falseValue) == false)
    }

    @Test("Data creation and access")
    func dataValue() {
        let bytes: [UInt8] = [0x48, 0x65, 0x6C, 0x6C, 0x6F]
        let plist = Plist.data(bytes)

        #expect(plist.isData)
        #expect(plist.data == bytes)
    }

    @Test("Array creation and access")
    func arrayValue() {
        let plist = Plist.array([
            .string("one"),
            .integer(2),
            .bool(true)
        ])

        #expect(plist.isArray)
        #expect(plist.array?.count == 3)
        #expect(String(plist[0]) == "one")
        #expect(Int(plist[1]) == 2)
        #expect(Bool(plist[2]) == true)
    }

    @Test("Dictionary creation and access")
    func dictionaryValue() {
        let plist = Plist.dictionary([
            ("name", .string("John")),
            ("age", .integer(30))
        ])

        #expect(plist.isDictionary)
        #expect(String(plist["name"]) == "John")
        #expect(Int(plist["age"]) == 30)
        #expect(String(plist.name) == "John")
        #expect(Int(plist.age) == 30)
    }

    @Test("Null access for missing keys")
    func nullAccess() {
        let plist = Plist.dictionary([("key", .string("value"))])

        #expect(plist["missing"].isNull)
        #expect(plist.missing.isNull)
        #expect(String(plist.missing) == "")
    }

    @Test("Subscript out of bounds returns null")
    func subscriptOutOfBounds() {
        let plist = Plist.array([.integer(1)])

        #expect(plist[5].isNull)
        #expect(plist[-1].isNull)
    }
}

@Suite("Plist Literal Tests")
struct PlistLiteralTests {
    @Test("Boolean literal")
    func boolLiteral() {
        let plist: Plist = true
        #expect(Bool(plist) == true)
    }

    @Test("Integer literal")
    func intLiteral() {
        let plist: Plist = 42
        #expect(Int64(plist) == 42)
    }

    @Test("Float literal")
    func floatLiteral() {
        let plist: Plist = 3.14
        #expect(Double(plist) == 3.14)
    }

    @Test("String literal")
    func stringLiteral() {
        let plist: Plist = "hello"
        #expect(String(plist) == "hello")
    }

    @Test("Array literal")
    func arrayLiteral() {
        let plist: Plist = [1, 2, 3]
        #expect(plist.array?.count == 3)
        #expect(Int64(plist[0]) == 1)
    }

    @Test("Dictionary literal")
    func dictionaryLiteral() {
        let plist: Plist = [
            "name": "Alice",
            "age": 25
        ]
        #expect(String(plist.name) == "Alice")
        #expect(Int64(plist.age) == 25)
    }

    @Test("Nested literal")
    func nestedLiteral() {
        let plist: Plist = [
            "user": [
                "name": "Bob",
                "tags": ["swift", "plist"]
            ]
        ]
        #expect(String(plist.user.name) == "Bob")
        #expect(String(plist.user.tags[0]) == "swift")
    }
}

@Suite("Plist Format Detection Tests")
struct PlistFormatTests {
    @Test("Detect XML format with declaration")
    func detectXMLWithDeclaration() {
        let xml = "<?xml version=\"1.0\"?><plist></plist>"
        let format = Plist.Format.detect(Array(xml.utf8))
        #expect(format == .xml)
    }

    @Test("Detect XML format with plist tag")
    func detectXMLWithPlist() {
        let xml = "<plist version=\"1.0\"><dict></dict></plist>"
        let format = Plist.Format.detect(Array(xml.utf8))
        #expect(format == .xml)
    }

    @Test("Detect binary format")
    func detectBinary() {
        let binary: [UInt8] = [0x62, 0x70, 0x6C, 0x69, 0x73, 0x74, 0x30, 0x30] // "bplist00"
        let format = Plist.Format.detect(binary)
        #expect(format == .binary)
    }

    @Test("Unknown format")
    func unknownFormat() {
        let unknown: [UInt8] = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05]
        let format = Plist.Format.detect(unknown)
        #expect(format == nil)
    }
}
