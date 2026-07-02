# swift-plist

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Property list parsing and serialization for Swift — auto-detected XML and binary formats, typed errors, and null-safe dynamic-member navigation.

## Quick Start

`Plist.parse(_:)` inspects the input's leading bytes and routes to the XML or binary parser, so one call handles both formats. Lookups on the result never trap: missing keys and type mismatches flow through as a null placeholder that typed extraction turns into `nil`.

```swift
import Plist

let plist = try Plist.parse(bytes)  // XML or binary — detected automatically

// Dynamic member lookup; a missing key yields .null, never a crash
let name = String?(plist.CFBundleName)              // Optional("MyApp")
let build = Int(plist.CFBundleVersion)              // nil unless <integer>
let capabilities = plist.UIRequiredDeviceCapabilities.array ?? []

// The same navigation via subscripts
let firstCapability = String?(plist["UIRequiredDeviceCapabilities"][0])
```

Building and serializing a plist is symmetric — literals produce values, `serialize` produces bytes:

```swift
import Plist

let preferences: Plist = [
    "theme": "dark",
    "fontSize": 14,
    "lineSpacing": 1.2,
    "autosave": true
]

let xml = preferences.serializeXML(pretty: true)      // String
let compact = preferences.serialize(format: .binary)  // [UInt8]
```

## Installation

Add swift-plist to your `Package.swift` (no tags are published yet; pin to `main`):

```swift
dependencies: [
    .package(url: "https://github.com/swift-foundations/swift-plist.git", branch: "main")
]
```

Add the product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Plist", package: "swift-plist")
    ]
)
```

Requirements: Swift 6.3 toolchain or later; macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26.

## Key Features

- **Format auto-detection** — `Plist.parse(_:)` recognizes the `bplist` magic and XML preambles; `Plist.Format.detect(_:)` exposes the check directly
- **Typed throws** — every parsing and deserialization API throws `Plist.Error`, an exhaustive `enum`; no `any Error` escapes the surface
- **Null-safe navigation** — dynamic member lookup and subscripts return a `.null` placeholder for missing keys and out-of-bounds indices instead of trapping
- **Order-preserving dictionaries** — dictionary members are stored as key-value pairs in document order, not rehashed
- **Value serialization** — the `Plist.Serializable` protocol round-trips custom types; `String`, `Int`, `Int64`, `Double`, `Bool`, `Array`, `Dictionary`, and `Optional` conform out of the box
- **Async input** — parse from any `AsyncSequence` of bytes, and stream newline-delimited plist documents with per-line error recovery

## Custom Types

Conform to `Plist.Serializable` to move between your types and plist bytes without intermediate casting:

```swift
import Plist

struct Preferences: Plist.Serializable {
    var theme: String
    var fontSize: Int

    static func serialize(_ value: Preferences) -> Plist {
        .dictionary([
            ("theme", .string(value.theme)),
            ("fontSize", .integer(value.fontSize))
        ])
    }

    static func deserialize(_ plist: Plist) throws(Plist.Error) -> Preferences {
        Preferences(
            theme: try String.deserialize(plist.theme),
            fontSize: try Int.deserialize(plist.fontSize)
        )
    }
}

let restored = try Preferences(plistBytes: bytes)
let stored = restored.plistBytes(format: .binary)
```

## Streaming

Parse from an async byte source, or process newline-delimited plist streams (one XML document per line) without buffering the whole input's parse results:

```swift
import Plist

// Collect an async byte sequence, then parse (auto-detected format)
let plist = try await Plist.parse(collecting: fileBytes)

// Newline-delimited plists: errors on one line do not stop the stream
for await result in Plist.ND.stream(lineBytes) {
    switch result {
    case .success(let plist):
        process(plist)
    case .failure(let error):
        log(error)
    }
}
```

Newline-delimited streaming supports the XML format only; binary plists require random access.

## Value Model

| Type | Purpose |
|------|---------|
| `Plist` | A plist value with dynamic member lookup, subscripts, literals, and factory methods |
| `Plist.Value` | The underlying enum: `.string`, `.integer(Int64)`, `.real(Double)`, `.bool`, `.data([UInt8])`, `.date(Double)`, `.array`, `.dictionary`, plus a `.null` placeholder |
| `Plist.Format` | `.xml` / `.binary`, with `detect(_:)` for magic-byte inspection |
| `Plist.Error` | Exhaustive typed error for parsing and deserialization |
| `Plist.Serializable` | Protocol for round-tripping custom types |
| `Plist.Prepared` | A `Sendable` parser handle from `Plist.parse.prepared()`, shareable across concurrent tasks |
| `Plist.ND` | Namespace for newline-delimited streaming |

Dates are stored as `Double` seconds since the Apple reference date (2001-01-01 00:00:00 UTC). Dictionary keys are always `String` and member order is preserved through parse–serialize round trips.

## Error Handling

All parsing throws `Plist.Error`:

```
Plist.Error
├── Format detection
│   ├── .unknownFormat
│   └── .unsupportedVersion(String)
├── XML parsing
│   ├── .invalidXML(message: String, line: Int, column: Int)
│   ├── .unexpectedElement(expected: String, got: String)
│   ├── .missingRequiredElement(String)
│   ├── .invalidBase64Data
│   └── .invalidDateFormat(String)
├── Binary parsing
│   ├── .invalidMagic
│   ├── .invalidTrailer
│   ├── .invalidObjectReference(UInt64)
│   ├── .invalidObjectType(UInt8)
│   ├── .integerOverflow
│   ├── .circularReference
│   └── .unexpectedEndOfData
└── Deserialization
    ├── .typeMismatch(expected: String, got: String)
    └── .missingKey(String)
```

Because the error type is concrete, `catch` patterns match cases directly:

```swift
do {
    let plist = try Plist.parse(bytes)
} catch .unknownFormat {
    // Input is neither an XML nor a binary plist
} catch .invalidXML(let message, let line, let column) {
    // Malformed XML — report message at line:column
} catch .unexpectedEndOfData {
    // Truncated binary plist
} catch {
    // Remaining Plist.Error cases; every case has a readable description
    report(error.description)
}
```

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at first public flip.*
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE](LICENSE.md).
