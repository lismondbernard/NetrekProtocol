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
        .library(name: "NetrekWire", targets: ["NetrekWire"]),
    ],
    targets: [
        .target(name: "NetrekWire"),
        .target(name: "NetrekProtocol", dependencies: ["NetrekWire"]),
        .testTarget(name: "NetrekWireTests", dependencies: ["NetrekWire"]),
        .testTarget(name: "NetrekProtocolTests", dependencies: ["NetrekProtocol"]),
    ]
)
