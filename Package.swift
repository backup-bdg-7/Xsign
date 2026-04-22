// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Xsign",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "XsignCore", targets: ["XsignCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/marmelroy/Zip.git", from: "2.1.2"),
        .package(url: "https://github.com/tsolomko/SWCompression", from: "4.8.6"),
        .package(url: "https://github.com/krzyzanowskim/OpenSSL", from: "3.3.3001"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.12.3"),
        .package(url: "https://github.com/tsolomko/BitByteData", from: "2.0.4"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
        .package(url: "https://github.com/httpswifter/swifter.git", from: "1.5.0"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.4.1")
    ],
    targets: [
        .target(
            name: "XsignCore",
            dependencies: [
                .product(name: "Zip", package: "Zip"),
                .product(name: "SWCompression", package: "SWCompression"),
                .product(name: "OpenSSL", package: "OpenSSL"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "BitByteData", package: "BitByteData"),
                "ZIPFoundation",
                .product(name: "Swifter", package: "swifter"),
                .product(name: "Lottie", package: "lottie-ios")
            ],
            path: "Xsign",
            exclude: [
                "Resources/Info.plist",
                "External/zsign/src/zsign.cpp",
                "External/zsign/test",
                "External/zsign/build"
            ]
        )
    ]
)
