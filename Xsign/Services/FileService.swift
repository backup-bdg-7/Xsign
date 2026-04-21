import Foundation
import SwiftData

class FileService {
    static let shared = FileService()

    private init() {}

    func importFile(at url: URL) async throws -> AppFile {
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "FileService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let fileName = url.lastPathComponent
        let type: FileType
        if fileName.hasSuffix(".ipa") { type = .ipa }
        else if fileName.hasSuffix(".dylib") { type = .dylib }
        else if fileName.hasSuffix(".deb") { type = .deb }
        else { type = .zip }

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)

        // Copy file to sandbox
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: url, to: destinationURL)

        let appFile = AppFile(
            name: fileName,
            fileName: fileName,
            relativePath: fileName,
            type: type,
            size: (try? destinationURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) } ?? 0
        )

        await PersistenceService.shared.context.insert(appFile)
        await PersistenceService.shared.save()

        await PersistenceService.shared.log(
            level: .info,
            category: "Import",
            message: "Imported \(fileName)"
        )

        return appFile
    }
}
