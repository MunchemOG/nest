// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NestKit",
    platforms: [.macOS("27.2")],
    products: [
        .library(name: "NestKit", targets: ["NestKit"]),
    ],
    targets: [
        .target(name: "NestKit", resources: [.copy("Resources/demo-day.jsonl")]),
        .testTarget(name: "NestKitTests", dependencies: ["NestKit"]),
    ]
)
