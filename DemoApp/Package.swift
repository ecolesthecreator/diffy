// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DiffViewDemo",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "DiffViewDemo",
            targets: ["DiffViewDemo"]
        )
    ],
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .executableTarget(
            name: "DiffViewDemo",
            dependencies: [
                .product(name: "DiffView", package: "diffy")
            ]
        )
    ]
)
