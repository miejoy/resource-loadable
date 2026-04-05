// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "resource-loadable",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "ResourceLoadable",
            targets: ["ResourceLoadable"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ResourceLoadable",
            dependencies: []),
        .testTarget(
            name: "ResourceLoadableTests",
            dependencies: ["ResourceLoadable"]),
    ]
)
