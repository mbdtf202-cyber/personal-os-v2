// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PersonalOSFoundation",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "PersonalOSFoundation",
            targets: ["PersonalOSFoundation"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PersonalOSFoundation",
            dependencies: []
        ),
        .testTarget(
            name: "PersonalOSFoundationTests",
            dependencies: ["PersonalOSFoundation"]
        )
    ]
)
