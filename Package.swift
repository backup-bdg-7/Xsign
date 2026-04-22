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
        .package(url: "https://github.com/vapor/vapor.git", exact: "4.104.0"),
        .package(url: "https://github.com/marmelroy/Zip.git", exact: "2.1.2"),
        .package(url: "https://github.com/tsolomko/SWCompression", exact: "4.8.6"),
        .package(url: "https://github.com/krzyzanowskim/OpenSSL", exact: "3.3.3001"),
        .package(url: "https://github.com/apple/swift-crypto.git", exact: "3.12.3"),
        .package(url: "https://github.com/tsolomko/BitByteData", exact: "2.0.4"),
        .package(url: "https://github.com/CLARATION/Zsign-Package.git", branch: "package"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
        .package(url: "https://github.com/httpswifter/swifter.git", from: "1.5.0")
    ],
    targets: [
        .target(
            name: "XsignCore",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Zip", package: "Zip"),
                .product(name: "SWCompression", package: "SWCompression"),
                .product(name: "OpenSSL", package: "OpenSSL"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "BitByteData", package: "BitByteData"),
                .product(name: "Zsign", package: "Zsign-Package"),
                "ZIPFoundation",
                .product(name: "Swifter", package: "swifter")
            ],
            path: "Xsign",
            exclude: ["Resources/Info.plist"]
        )
    ]
)
