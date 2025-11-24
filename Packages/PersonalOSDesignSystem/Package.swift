// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PersonalOSDesignSystem",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PersonalOSDesignSystem",
            targets: ["PersonalOSDesignSystem"]
        )
    ],
    dependencies: [
        .package(path: "../PersonalOSFoundation")
    ],
    targets: [
        .target(
            name: "PersonalOSDesignSystem",
            dependencies: ["PersonalOSFoundation"],
            resources: [.process("Resources")]
        )
    ]
)
