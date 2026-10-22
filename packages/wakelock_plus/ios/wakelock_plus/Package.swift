// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "wakelock_plus",
    // Irenefy (F5): 13.0 invece di 11.0. FlutterFramework (Flutter 3.41) chiede
    // iOS 13 e Xcode 26 rifiuta il pacchetto con un minimo più basso; la 1.8.1
    // lo corregge ma richiede Flutter 3.44.
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "wakelock-plus", targets: ["wakelock_plus"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "wakelock_plus",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("Resources")
            ],
            cSettings: [
                .headerSearchPath("include/wakelock_plus")
            ]
        )
    ]
)