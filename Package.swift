// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "NotchHub",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "NotchHub", targets: ["NotchHub"])
    ],
    targets: [
        .executableTarget(
            name: "NotchHub",
            path: "Sources/NotchHub"
        ),
        .testTarget(
            name: "NotchHubTests",
            dependencies: ["NotchHub"],
            path: "Tests/NotchHubTests"
        )
    ]
)
