// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PersonalOSCore",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PersonalOSCore",
            targets: ["PersonalOSCore"]
        )
    ],
    dependencies: [
        .package(path: "../PersonalOSFoundation"),
        .package(path: "../PersonalOSModels")
    ],
    targets: [
        .target(
            name: "PersonalOSCore",
            dependencies: [
                "PersonalOSFoundation",
                "PersonalOSModels"
            ]
        ),
        .testTarget(
            name: "PersonalOSCoreTests",
            dependencies: ["PersonalOSCore"]
        )
    ]
)
