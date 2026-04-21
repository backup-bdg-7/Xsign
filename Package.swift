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
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19")
    ],
    targets: [
        .target(
            name: "XsignCore",
            dependencies: ["ZIPFoundation"],
            path: "Xsign",
            exclude: ["Resources/Info.plist"]
        )
    ]
)
