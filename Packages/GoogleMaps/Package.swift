// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "GoogleMaps",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "GoogleMaps", targets: ["GoogleMapsTarget"])
    ],
    targets: [
        .binaryTarget(
            name: "GoogleMaps",
            path: "GoogleMaps.xcframework"
        ),
        .target(
            name: "GoogleMapsTarget",
            dependencies: ["GoogleMaps"],
            path: "Maps",
            sources: ["GMSEmpty.m"],
            resources: [.copy("Resources/GoogleMapsResources/GoogleMaps.bundle")],
            publicHeadersPath: "Sources",
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedLibrary("z"),
                .linkedFramework("Accelerate"),
                .linkedFramework("Contacts"),
                .linkedFramework("CoreData"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreImage"),
                .linkedFramework("CoreLocation"),
                .linkedFramework("CoreTelephony"),
                .linkedFramework("CoreText"),
                .linkedFramework("GLKit"),
                .linkedFramework("ImageIO"),
                .linkedFramework("Metal"),
                .linkedFramework("OpenGLES"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("Security"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("UIKit"),
                .linkedFramework("MetricKit")
            ]
        )
    ]
)
