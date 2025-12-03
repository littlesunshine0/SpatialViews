// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpatialViews",
    platforms: [
        .macOS(.v13), .iOS(.v17)
    ],
    products: [
        .library(name: "SpatialViews", targets: ["SpatialViews"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "SpatialViews",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            path: "SpatialViews"
        )
    ]
)
