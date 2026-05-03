import Foundation
import SwiftData

class FileService {
    static let shared = FileService()
    private init() {}
    
    func importFile(at url: URL) async throws -> AppFile {
        guard url.startAccessingSecurityScopedResource() else { throw NSError(domain: "File", code: 1) }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let fileName = url.lastPathComponent.lowercased()
        let type: FileType
        
        // Only allow .ipa, .dylib, .deb files
        if fileName.hasSuffix(".ipa") { type = .ipa }
        else if fileName.hasSuffix(".dylib") { type = .dylib }
        else if fileName.hasSuffix(".deb") { type = .deb }
        else {
            // Remove the file if it was copied
            throw NSError(domain: "File", code: 2, userInfo: [NSLocalizedDescriptionKey: "Only .ipa, .dylib, and .deb files are supported"])
        }
    
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dest = docs.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: dest.path) { try? FileManager.default.removeItem(at: dest) }
        try FileManager.default.copyItem(at: url, to: dest)
        
        let app = AppFile(name: fileName, fileName: fileName, relativePath: fileName, type: type, size: 0)
        await PersistenceService.shared.context.insert(app)
        await PersistenceService.shared.save()
        return app
    }
}
