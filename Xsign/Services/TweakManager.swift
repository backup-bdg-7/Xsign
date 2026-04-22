import Foundation
import SWCompression

/**
 * TweakManager handles the extraction of binaries from DEB packages.
 * It uses SWCompression for robust archive traversal.
 */
class TweakManager {
    static let shared = TweakManager()
    private init() {}

    /// Extracts a dylib from a .deb package or returns the URL if already a .dylib
    func prepareTweak(at url: URL) throws -> URL {
        if url.pathExtension == "dylib" {
            return url
        } else if url.pathExtension == "deb" {
            return try extractDylibFromDeb(at: url)
        }
        return url
    }

    private func extractDylibFromDeb(at url: URL) throws -> URL {
        let data = try Data(contentsOf: url)

        // Step 1: Un-AR the DEB container
        let arArchive = try ArArchive(data: data)
        guard let dataEntry = arArchive.files.first(where: { $0.name.contains("data.tar") }) else {
            throw NSError(domain: "TweakManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "data.tar not found"])
        }

        // Step 2: Un-Gzip and Un-TAR the data payload
        let tarData = try GzipArchive.unarchive(archive: dataEntry.data)
        let tarArchive = try TarArchive(data: tarData)

        // Step 3: Identify the .dylib binary
        guard let dylibEntry = tarArchive.files.first(where: { $0.name.hasSuffix(".dylib") }) else {
            throw NSError(domain: "TweakManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "No dylib in package"])
        }

        let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".dylib")
        try dylibEntry.data.write(to: tempPath)
        return tempPath
    }
}
