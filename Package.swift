// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-plist",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(name: "Plist", targets: ["Plist"])
    ],
    dependencies: [
        .package(path: "../swift-xml"),
        .package(path: "../swift-async"),
        .package(path: "../../swift-ietf/swift-rfc-4648"),
        .package(path: "../../swift-iso/swift-iso-8601")
    ],
    targets: [
        // Primitives: Plist, Plist.Value, Plist.Error
        .target(
            name: "Plist Primitives",
            dependencies: []
        ),
        // XML parser/serializer
        .target(
            name: "Plist XML",
            dependencies: [
                "Plist Primitives",
                .product(name: "XML", package: "swift-xml"),
                .product(name: "RFC 4648", package: "swift-rfc-4648"),
                .product(name: "ISO 8601", package: "swift-iso-8601")
            ]
        ),
        // Binary parser/serializer
        .target(
            name: "Plist Binary",
            dependencies: [
                "Plist Primitives"
            ]
        ),
        // Main target: re-exports all and adds convenience parsing
        .target(
            name: "Plist",
            dependencies: [
                "Plist Primitives",
                "Plist XML",
                "Plist Binary",
                .product(name: "Async", package: "swift-async")
            ]
        ),
        .testTarget(
            name: "Plist Tests",
            dependencies: [
                "Plist",
            ]
        ),
        .testTarget(
            name: "Plist XML Tests",
            dependencies: [
                "Plist XML",
            ]
        ),
        .testTarget(
            name: "Plist Binary Tests",
            dependencies: [
                "Plist Binary",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)


for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableExperimentalFeature("SuppressedAssociatedTypesWithDefaults"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
