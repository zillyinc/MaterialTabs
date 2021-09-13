// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MaterialTabs",
    products: [
        .library(name: "MaterialTabs", targets: ["MaterialTabs"]),
    ],
    targets: [
        .target(
            name: "MaterialTabs",
            dependencies: [],
            path: "Sources",
            publicHeadersPath: "."
        ),
    ]
)
