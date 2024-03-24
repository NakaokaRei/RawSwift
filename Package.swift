// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RawSwift",
    targets: [
        .executableTarget(
            name: "example",
            dependencies: ["libraw"],
            path: "Sources"
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
