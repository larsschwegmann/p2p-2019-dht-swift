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
        .package(url: "https://github.com/larsschwegmann/SwiftCLI.git", .branch("master")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/larsschwegmann/UInt256.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "DHTSwift",
            dependencies: ["NIO", "NIOExtras", "SwiftCLI", "CryptoSwift", "UInt256"]),
        .target(
            name: "DHTSwiftExecutable",
            dependencies: ["DHTSwift"]),
        .testTarget(
            name: "DHTSwiftTests",
            dependencies: ["DHTSwift"]),
    ]
)
