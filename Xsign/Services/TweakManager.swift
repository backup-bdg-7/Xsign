import Foundation
import ZIPFoundation
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
        
        // Parse the deb file (.deb files are ar archives)
        // The ar format has a global magic "!<arch>\n" followed by file entries
        guard let archive = ArArchive(data: data) else {
            throw NSError(domain: "TweakManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse deb file"])
        }
        
        // Find the data.tar file in the archive (could be data.tar, data.tar.gz, data.tar.xz, etc.)
        guard let dataEntry = archive.entries.first(where: { $0.name.hasPrefix("data.tar") }) else {
            throw NSError(domain: "TweakManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data.tar found in deb file"])
        }

        // Decompress if needed
        var tarData = dataEntry.data
        if dataEntry.name.hasSuffix(".gz") {
            tarData = try GzipArchive.unarchive(archive: dataEntry.data)
        } else if dataEntry.name.hasSuffix(".xz") {
            tarData = try XZArchive.unarchive(archive: dataEntry.data)
        } else if dataEntry.name.hasSuffix(".bz2") {
            tarData = try BZip2.decompress(data: dataEntry.data)
        }

        // Parse the tar archive
        let tar = try TarContainer.open(container: tarData)
        
        // Find the dylib file
        guard let dylibEntry = tar.first(where: { $0.info.name.hasSuffix(".dylib") }) else {
            throw NSError(domain: "TweakManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "No dylib found in deb file"])
        }

        // Write to temp location
        guard let dylibData = dylibEntry.data else {
            throw NSError(domain: "TweakManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Dylib data is nil"])
        }
        
        let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".dylib")
        try dylibData.write(to: tempPath)
        return tempPath
    }
}

// Simple AR archive parser for .deb files
struct ArArchive {
    let entries: [ArEntry]
    
    init?(data: Data) {
        // Check for ar magic
        let magic = Data("!<arch>\n".utf8)
        guard data.count > magic.count && data.prefix(magic.count) == magic else {
            return nil
        }
        
        var entries: [ArEntry] = []
        var offset = magic.count
        
        while offset < data.count {
            // Each entry has a header of 60 bytes
            guard offset + 60 <= data.count else { break }
            
            let headerData = data.subdata(in: offset..<offset + 60)
            guard let header = String(data: headerData, encoding: .ascii) else { break }
            
            // Parse header fields
            // Format: name (16) + timestamp (12) + ownerID (6) + groupID (6) + mode (8) + size (10) + ` (2)
            let name = header.prefix(16).trimmingCharacters(in: .whitespacesAndNewlines)
            let sizeStr = header.dropFirst(16 + 12 + 6 + 6 + 8).prefix(10).trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let size = Int(sizeStr) else { break }
            
            offset += 60
            
            // Read file data
            guard offset + size <= data.count else { break }
            let fileData = data.subdata(in: offset..<offset + size)
            
            entries.append(ArEntry(name: name, data: fileData))
            
            // Align to even byte boundary
            offset += size
            if offset % 2 != 0 {
                offset += 1
            }
        }
        
        self.entries = entries
    }
}

struct ArEntry {
    let name: String
    let data: Data
}
