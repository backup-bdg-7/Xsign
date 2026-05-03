// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "Zsign",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "Zsign",
            targets: ["Zsign"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/OpenSSL", from: "3.3.3001")
    ],
    targets: [
        .target(
            name: "ZsignC",
            dependencies: [
                .product(name: "OpenSSL", package: "OpenSSL")
            ],
            path: "src",
            exclude: [
                "common/archive.cpp",
                "zsign.cpp"
            ],
            sources: [
                "archo.cpp",
                "bundle.cpp",
                "certcheck.cpp",
                "macho.cpp",
                "openssl.cpp",
                "signing.cpp",
                "zsign_c_wrapper.cpp",
                "common/base64.cpp",
                "common/fs.cpp",
                "common/json.cpp",
                "common/log.cpp",
                "common/sha.cpp",
                "common/timer.cpp",
                "common/util.cpp"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("common"),
            ],
            cxxSettings: [
                .headerSearchPath("."),
                .headerSearchPath("common"),
                .unsafeFlags(["-std=c++17"])
            ]
        ),
        .target(
            name: "Zsign",
            dependencies: ["ZsignC"],
            path: "Sources"
        ),
    ]
)
