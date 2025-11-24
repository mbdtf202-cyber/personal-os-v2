// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PersonalOSModels",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PersonalOSModels",
            targets: ["PersonalOSModels"]
        )
    ],
    dependencies: [
        .package(path: "../PersonalOSFoundation")
    ],
    targets: [
        .target(
            name: "PersonalOSModels",
            dependencies: ["PersonalOSFoundation"]
        )
    ]
)
