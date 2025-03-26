// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "KeychainManager",
    platforms: [
        .iOS(.v13),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "KeychainManager",
            targets: ["KeychainManager"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "KeychainManager",
            dependencies: []
        ),
        .testTarget(
            name: "KeychainManagerTests",
            dependencies: ["KeychainManager"]
        ),
    ]
)
