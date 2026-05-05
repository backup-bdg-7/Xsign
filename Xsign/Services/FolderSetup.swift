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
        
        // Create imports folder
        let importsDir = documentsDir.appendingPathComponent("imports", isDirectory: true)
        if !fileManager.fileExists(atPath: importsDir.path) {
            try? fileManager.createDirectory(at: importsDir, withIntermediateDirectories: true)
        }
        
        // Create archives folder (for signed apps)
        let archivesDir = documentsDir.appendingPathComponent("archives", isDirectory: true)
        if !fileManager.fileExists(atPath: archivesDir.path) {
            try? fileManager.createDirectory(at: archivesDir, withIntermediateDirectories: true)
        }
        
        // Create dylibs folder
        let dylibsDir = documentsDir.appendingPathComponent("dylibs", isDirectory: true)
        if !fileManager.fileExists(atPath: dylibsDir.path) {
            try? fileManager.createDirectory(at: dylibsDir, withIntermediateDirectories: true)
        }
        
        // Create deb folder
        let debDir = documentsDir.appendingPathComponent("debs", isDirectory: true)
        if !fileManager.fileExists(atPath: debDir.path) {
            try? fileManager.createDirectory(at: debDir, withIntermediateDirectories: true)
        }
        
        // Create logs folder if not exists (logs file is in documents root)
        let logsDir = documentsDir.appendingPathComponent("logs", isDirectory: true)
        if !fileManager.fileExists(atPath: logsDir.path) {
            try? fileManager.createDirectory(at: logsDir, withIntermediateDirectories: true)
        }
    }
}
