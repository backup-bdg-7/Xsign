// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Xsign",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(name: "Xsign", targets: ["Xsign"])
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
        .package(url: "https://github.com/httpswifter/swifter.git", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "Xsign",
            dependencies: [
                "ZIPFoundation",
                .product(name: "Swifter", package: "swifter")
            ],
            path: "Xsign",
            exclude: ["Resources/Info.plist"],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ],
            linkerSettings: [
                .linkedFramework("CryptoKit"),
                .linkedFramework("Network"),
                .linkedFramework("Security")
            ]
        )
    ],
    cxxLanguageStandard: .cxx17
)
