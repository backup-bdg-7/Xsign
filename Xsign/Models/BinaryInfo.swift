import Foundation

struct MachOInfo {
    let architectures: [String]
    let linkedLibraries: [String]
    let platform: String
    let minOS: String
}

struct DebInfo {
    let packageName: String
    let version: String
    let architecture: String
    let maintainer: String
    let description: String
    let dependencies: [String]
}
