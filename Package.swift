// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "NetrekProtocol",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
    ],
    products: [
        .library(name: "NetrekProtocol", targets: ["NetrekProtocol"]),
    ],
    targets: [
        .target(name: "NetrekProtocol"),
        .testTarget(name: "NetrekProtocolTests", dependencies: ["NetrekProtocol"]),
    ]
)
