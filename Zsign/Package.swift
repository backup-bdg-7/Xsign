// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "Zsign",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_15),
        .tvOS(.v12),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "ZsignC",
            targets: ["ZsignC"]
        ),
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
                "macho.cpp",
                "openssl.cpp",
                "signing.cpp",
                "common/base64.cpp",
                "common/fs.cpp",
                "common/json.cpp",
                "common/log.cpp",
                "common/sha.cpp",
                "common/timer.cpp",
                "common/util.cpp",
                "utils.mm"
            ],
            publicHeadersPath: "include",
            cxxSettings: [
                .headerSearchPath("."),
                .headerSearchPath("common"),
                .unsafeFlags(["-std=c++17"])
            ],
            linkerSettings: [
                .linkedLibrary("ssl"),
                .linkedLibrary("crypto"),
                .linkedLibrary("z"),
            ]
        ),
        .target(
            name: "Zsign",
            dependencies: [
                "ZsignC"
            ],
            path: "swift",
            sources: [
                "zsign.swift"
            ]
        )
    ]
)
