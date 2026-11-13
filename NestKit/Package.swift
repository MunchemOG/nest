// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NestKit",
    platforms: [.macOS("27.2")],
    products: [
        .library(name: "NestKit", targets: ["NestKit"]),
        .executable(name: "nest-run", targets: ["nest-run"]),
    ],
    targets: [
        .target(name: "NestKit", resources: [.copy("Resources/demo-day.jsonl"), .copy("Resources/Fonts")]),
        .executableTarget(name: "nest-run", dependencies: ["NestKit"]),
        .testTarget(name: "NestKitTests", dependencies: ["NestKit"]),
    ]
)
