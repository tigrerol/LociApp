££// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SuperMemoKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "SuperMemoKit",
            targets: ["SuperMemoKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SuperMemoKit",
            dependencies: []
        ),
        .testTarget(
            name: "SuperMemoKitTests",
            dependencies: ["SuperMemoKit"]
        ),
    ]
)
