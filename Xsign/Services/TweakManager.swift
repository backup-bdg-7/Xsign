import Foundation
import SWCompression

class TweakManager {
    static let shared = TweakManager()
    private init() {}

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
        // Implementation using SWCompression to extract dylib from DEB (ar -> tar.gz)
        let container = try ArArchive(data: data)
        guard let dataEntry = container.files.first(where: { $0.name.contains("data.tar") }) else {
            throw NSError(domain: "TweakManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "data.tar not found in DEB"])
        }

        let tarData = try GzipArchive.unarchive(archive: dataEntry.data)
        let tar = try TarArchive(data: tarData)

        guard let dylibEntry = tar.files.first(where: { $0.name.hasSuffix(".dylib") }) else {
            throw NSError(domain: "TweakManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "No dylib found in DEB package"])
        }

        let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".dylib")
        try dylibEntry.data.write(to: tempPath)
        return tempPath
    }
}
