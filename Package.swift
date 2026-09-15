// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LuminaKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "LuminaKit", targets: ["LuminaKit"])
    ],
    targets: [
        .target(
            name: "LuminaKit",
            path: "Sources/LuminaKit",
            sources: [
                "LuminaKit.swift",
                "IridescentBlob/IridescentBlobView.swift"
            ],
            resources: [
                .copy("IridescentBlob/IridescentBlob.metal")
            ]
        )
    ]
)
