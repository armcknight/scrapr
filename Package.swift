// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "scrapr",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .executable(name: "scrapr", targets: ["scrapr"]),
        .library(name: "scrapr-lib", targets: ["scrapr-lib"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(name: "SwiftArmcknight", path: "swift-armcknight")
    ],
    targets: [
        .executableTarget(
            name: "scrapr",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SwiftArmcknight", package: "SwiftArmcknight"),
                "scrapr-lib",
            ]
        ),
        .target(name: "scrapr-lib", dependencies:[
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "Logging", package: "swift-log"),
        ]
        )
    ]
)
