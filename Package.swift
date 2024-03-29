// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "DHTSwift",
    platforms: [
        .macOS(.v10_14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.0.0-alpha"),
        .package(url: "https://github.com/larsschwegmann/SwiftCLI.git", .branch("master")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/larsschwegmann/UInt256.git", .branch("master")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/larsschwegmann/HeliumLogger.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "DHTSwift",
            dependencies: ["NIO", "NIOConcurrencyHelpers", "NIOExtras","AsyncKit", "SwiftCLI", "CryptoSwift", "UInt256", "Logging", "HeliumLogger"]),
        .target(
            name: "DHTSwiftExecutable",
            dependencies: ["DHTSwift"]),
        .testTarget(
            name: "DHTSwiftTests",
            dependencies: ["DHTSwift"]),
    ]
)
