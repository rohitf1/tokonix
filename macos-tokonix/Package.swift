// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Tokonix",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "tokonix", targets: ["Tokonix"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Tokonix",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "TokonixTests",
            dependencies: ["Tokonix"]
        )
    ]
)
