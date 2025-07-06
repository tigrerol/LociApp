// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LociApp",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "LociApp",
            targets: ["LociApp"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LociApp",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "LociAppTests",
            dependencies: ["LociApp"],
            path: "Tests"
        ),
    ]
)