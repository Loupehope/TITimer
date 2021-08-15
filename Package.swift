// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TITimer",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "TITimer",
            targets: ["TITimer"]),
    ],
    targets: [
        .target(
            name: "TITimer",
            dependencies: []),
        .testTarget(
            name: "TITimerTests",
            dependencies: ["TITimer"]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
