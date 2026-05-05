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
        let destinationFolder: String
        
        // Determine file type and destination folder
        if fileName.hasSuffix(".ipa") { 
            type = .ipa
            destinationFolder = "apps"
        } else if fileName.hasSuffix(".dylib") { 
            type = .dylib
            destinationFolder = "dylibs"
        } else if fileName.hasSuffix(".deb") { 
            type = .deb
            destinationFolder = "debs"
        } else {
            throw NSError(domain: "File", code: 2, userInfo: [NSLocalizedDescriptionKey: "Only .ipa, .dylib, and .deb files are supported"])
        }
    
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destFolder = docs.appendingPathComponent(destinationFolder, isDirectory: true)
        let dest = destFolder.appendingPathComponent(fileName)
        
        // Create destination folder if needed
        if !FileManager.default.fileExists(atPath: destFolder.path) {
            try? FileManager.default.createDirectory(at: destFolder, withIntermediateDirectories: true)
        }
        
        if FileManager.default.fileExists(atPath: dest.path) { 
            try? FileManager.default.removeItem(at: dest) 
        }
        try FileManager.default.copyItem(at: url, to: dest)
        
        // Store relative path from documents directory
        let relativePath = "\(destinationFolder)/\(fileName)"
        let app = AppFile(name: fileName, fileName: fileName, relativePath: relativePath, type: type, size: 0)
        await PersistenceService.shared.context.insert(app)
        await PersistenceService.shared.save()
        return app
    }
}
