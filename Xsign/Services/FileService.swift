import Foundation
import SwiftData

class FileService {
    static let shared = FileService()
    private init() {}
    func importFile(at url: URL) async throws -> AppFile {
        guard url.startAccessingSecurityScopedResource() else { throw NSError(domain: "File", code: 1) }
        defer { url.stopAccessingSecurityScopedResource() }
        let fileName = url.lastPathComponent
        let type: FileType = fileName.hasSuffix(".ipa") ? .ipa : (fileName.hasSuffix(".dylib") ? .dylib : .zip)
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
