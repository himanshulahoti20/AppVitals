// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "AppVitals",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "AppVitals", targets: ["AppVitals"]),
        .library(name: "AppVitalsCore", targets: ["AppVitalsCore"]),
        .library(name: "AppVitalsNetwork", targets: ["AppVitalsNetwork"]),
        .library(name: "AppVitalsUI", targets: ["AppVitalsUI"]),
        .library(name: "AppVitalsStorage", targets: ["AppVitalsStorage"]),
        .library(name: "AppVitalsTestingSupport", targets: ["AppVitalsTestingSupport"]),
    ],
    targets: [
        .target(name: "AppVitalsCore"),
        .target(
            name: "AppVitalsStorage",
            dependencies: ["AppVitalsCore"]
        ),
        .target(
            name: "AppVitalsNetwork",
            dependencies: ["AppVitalsCore", "AppVitalsStorage"]
        ),
        .target(
            name: "AppVitalsUI",
            dependencies: ["AppVitalsCore", "AppVitalsStorage", "AppVitalsNetwork"]
        ),
        .target(
            name: "AppVitals",
            dependencies: ["AppVitalsCore", "AppVitalsStorage", "AppVitalsNetwork", "AppVitalsUI"]
        ),
        .target(
            name: "AppVitalsTestingSupport",
            dependencies: ["AppVitalsCore", "AppVitalsStorage", "AppVitalsNetwork"]
        ),
        .testTarget(
            name: "AppVitalsCoreTests",
            dependencies: ["AppVitalsCore"]
        ),
        .testTarget(
            name: "AppVitalsStorageTests",
            dependencies: ["AppVitalsCore", "AppVitalsStorage"]
        ),
        .testTarget(
            name: "AppVitalsNetworkTests",
            dependencies: ["AppVitalsCore", "AppVitalsNetwork", "AppVitalsStorage", "AppVitalsTestingSupport"]
        ),
        .testTarget(
            name: "AppVitalsTests",
            dependencies: ["AppVitals"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
