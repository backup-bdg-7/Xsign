import Foundation

// MARK: - Folder Structure Setup
// Sets up the proper folder structure for XSign like Feather does
struct FolderSetup {
    static let shared = FolderSetup()
    private init() { setupFolders() }
    
    func setupFolders() {
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Create certificates folder
        let certsDir = documentsDir.appendingPathComponent("certificates", isDirectory: true)
        if !fileManager.fileExists(atPath: certsDir.path) {
            try? fileManager.createDirectory(at: certsDir, withIntermediateDirectories: true)
        }
        
        // Create apps folder (for .ipa files - renamed from imports)
        let appsDir = documentsDir.appendingPathComponent("apps", isDirectory: true)
        if !fileManager.fileExists(atPath: appsDir.path) {
            try? fileManager.createDirectory(at: appsDir, withIntermediateDirectories: true)
        }
        
        // Create dylibs folder
        let dylibsDir = documentsDir.appendingPathComponent("dylibs", isDirectory: true)
        if !fileManager.fileExists(atPath: dylibsDir.path) {
            try? fileManager.createDirectory(at: dylibsDir, withIntermediateDirectories: true)
        }
        
        // Create debs folder
        let debDir = documentsDir.appendingPathComponent("debs", isDirectory: true)
        if !fileManager.fileExists(atPath: debDir.path) {
            try? fileManager.createDirectory(at: debDir, withIntermediateDirectories: true)
        }
        
        // Create signed folder (for signed apps - replaces archives)
        let signedDir = documentsDir.appendingPathComponent("signed", isDirectory: true)
        if !fileManager.fileExists(atPath: signedDir.path) {
            try? fileManager.createDirectory(at: signedDir, withIntermediateDirectories: true)
        }
        
        // Create sources folder (for local signing sources like Vapor, backdoor.dev)
        let sourcesDir = documentsDir.appendingPathComponent("sources", isDirectory: true)
        if !fileManager.fileExists(atPath: sourcesDir.path) {
            try? fileManager.createDirectory(at: sourcesDir, withIntermediateDirectories: true)
        }
        
        // Create logs folder
        let logsDir = documentsDir.appendingPathComponent("logs", isDirectory: true)
        if !fileManager.fileExists(atPath: logsDir.path) {
            try? fileManager.createDirectory(at: logsDir, withIntermediateDirectories: true)
        }
        
        // Create default categories
        PersistenceService.shared.createDefaultCategories()
    }
}
