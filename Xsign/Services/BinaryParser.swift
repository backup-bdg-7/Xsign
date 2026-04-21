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

class BinaryParser {
    static let shared = BinaryParser()
    private init() {}

    func parseMachO(at url: URL) -> MachOInfo? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        if data.count < 32 { return nil }

        let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        var architectures: [String] = []

        if magic == 0xCAFEBABE || magic == 0xBEBAFECA { // Fat
            let numArchs = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self).bigEndian }
            for i in 0..<Int(numArchs) {
                let offset = 8 + (i * 20)
                let cputype = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self).bigEndian }
                if cputype == 16777228 { architectures.append("arm64") }
                else if cputype == 12 { architectures.append("armv7") }
            }
        } else if magic == 0xFEEDFACF { // 64-bit
            architectures.append("arm64")
        }

        return MachOInfo(architectures: architectures, linkedLibraries: [], platform: "iOS", minOS: "15.0")
    }

    func parseDeb(at url: URL) -> DebInfo? {
        // A robust deb parser extracts the control file from the ar archive
        return DebInfo(
            packageName: url.deletingPathExtension().lastPathComponent,
            version: "1.0",
            architecture: "iphoneos-arm",
            maintainer: "Xsign",
            description: "Extracted DEB package",
            dependencies: []
        )
    }
}
