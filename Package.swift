// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RawSwift",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "RawSwift", targets: ["RawSwift"])
    ],
    targets: [
        .target(
            name: "RawSwift",
            dependencies: ["libraw"]
        ),
        .executableTarget(
            name: "Sample",
            dependencies: ["libraw"]
        ),
        .systemLibrary(
            name: "libraw",
            pkgConfig: "libraw",
            providers: [
                .brew(["libraw"])
            ]
        )
    ]
)
