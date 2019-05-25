// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "dht-module",
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.0.0"),
        .package(url: "https://github.com/larsschwegmann/SwiftCLI.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "dht-module",
            dependencies: ["NIO", "NIOExtras", "SwiftCLI"]),
        .testTarget(
            name: "dht-moduleTests",
            dependencies: ["dht-module"]),
    ]
)
