// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PersonalOSDashboard",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "PersonalOSDashboard",
            targets: ["PersonalOSDashboard"]
        )
    ],
    dependencies: [
        .package(path: "../PersonalOSFoundation"),
        .package(path: "../PersonalOSCore"),
        .package(path: "../PersonalOSModels"),
        .package(path: "../PersonalOSDesignSystem")
    ],
    targets: [
        .target(
            name: "PersonalOSDashboard",
            dependencies: [
                "PersonalOSFoundation",
                "PersonalOSCore",
                "PersonalOSModels",
                "PersonalOSDesignSystem"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .define("FEATURE_DASHBOARD", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "PersonalOSDashboardTests",
            dependencies: ["PersonalOSDashboard"]
        )
    ]
)
