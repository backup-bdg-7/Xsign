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
        
        // Parse the deb file - AR Archive
        let ar = try ARArchive(archive: data)
        
        // Find the data.tar file in the archive
        guard let dataEntry = ar.files.first(where: { $0.name.contains("data.tar") }) else {
            throw NSError(domain: "TweakManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data.tar found in deb"])
        }

        // Decompress if needed
        var tarData = dataEntry.data
        if dataEntry.name.hasSuffix(".gz") {
            tarData = try GzipArchive.unarchive(archive: dataEntry.data)
        } else if dataEntry.name.hasSuffix(".xz") {
            tarData = try LZMA2.decompress(data: dataEntry.data)
        }

        // Parse the tar archive
        let tar = try TarArchive(archive: tarData)
        
        // Find the dylib file
        guard let dylibEntry = tar.files.first(where: { $0.name.hasSuffix(".dylib") }) else {
            throw NSError(domain: "TweakManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "No dylib found in tar"])
        }

        // Write to temp location
        let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".dylib")
        try dylibEntry.data.write(to: tempPath)
        return tempPath
    }
}
