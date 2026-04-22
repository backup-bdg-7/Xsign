// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Xsign",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "Xsign", targets: ["Xsign"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", exact: "4.104.0"),
        .package(url: "https://github.com/marmelroy/Zip.git", exact: "2.1.2"),
        .package(url: "https://github.com/tsolomko/SWCompression", exact: "4.8.6"),
        .package(url: "https://github.com/krzyzanowskim/OpenSSL", exact: "3.3.3001"),
        .package(url: "https://github.com/apple/swift-crypto.git", exact: "3.12.3"),
        .package(url: "https://github.com/tsolomko/BitByteData", exact: "2.0.4")
    ],
    targets: [
        .target(
            name: "Xsign",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Zip", package: "Zip"),
                .product(name: "SWCompression", package: "SWCompression"),
                .product(name: "OpenSSL", package: "OpenSSL"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "BitByteData", package: "BitByteData")
            ],
            path: "Xsign",
            exclude: ["Resources/Info.plist"]
        )
    ]
)
