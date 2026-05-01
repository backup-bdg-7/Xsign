// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Xsign",
    platforms: [
        .iOS(.v17)  // SwiftData requires iOS 17+
    ],
    products: [
        .library(
            name: "Xsign",
            targets: ["Xsign"]),
    ],
    dependencies: [
        // ZIP Foundation for zip operations
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
        // Lottie for animations
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.4.1"),
        // BitByteData for binary parsing
        .package(url: "https://github.com/tsolomko/BitByteData", from: "2.0.4"),
        // SWCompression for compression utilities
        .package(url: "https://github.com/tsolomko/SWCompression", from: "4.8.6"),
        // Swift Crypto (instead of OpenSSL for pure Swift)
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.12.3"),
        // Vapor (if needed for server components)
        .package(url: "https://github.com/vapor/vapor.git", from: "4.92.0"),
        // Zip package
        .package(url: "https://github.com/marmelroy/Zip.git", from: "2.1.2"),
    ],
    targets: [
        .target(
            name: "XsignBridge",
            dependencies: [],
            path: "Xsign/App/Bridge",
            cSettings: [
                .headerSearchPath("../../External")
            ]
        ),
        .target(
            name: "Xsign",
            dependencies: [
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                .product(name: "lottie-ios", package: "lottie-ios"),
                .product(name: "BitByteData", package: "BitByteData"),
                .product(name: "SWCompression", package: "SWCompression"),
                .product(name: "swift-crypto", package: "swift-crypto"),
                .product(name: "vapor", package: "vapor"),
                .product(name: "Zip", package: "Zip"),
                "XsignBridge",
            ],
            path: "Xsign",
            exclude: ["Resources", "External", "App/Bridge"],
            sources: ["App", "Models", "Services", "Shared", "Views"],
            cSettings: [
                .headerSearchPath("External")
            ]
        ),
    ]
)
