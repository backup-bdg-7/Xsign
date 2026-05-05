import Foundation
import SwiftData

@MainActor
class PersistenceService {
    static let shared = PersistenceService()
    let container: ModelContainer
    private let logsFileName = "xsign_logs.txt"
    
    init() {
        let schema = Schema([AppFile.self, Certificate.self, Category.self, Entitlement.self, AppLog.self])
        container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: false)])
        setupLogsFile()
    }
    
    var context: ModelContext { container.mainContext }
    
    func save() { try? context.save() }
    
    func log(level: LogLevel, category: String, message: String, details: String? = nil) {
        let log = AppLog(level: level, category: category, message: message, details: details)
        context.insert(log)
        save()
        writeLogToFile(log)
    }
    
    func setupLogsFile() {
        let logsURL = getLogsFileURL()
        if !FileManager.default.fileExists(atPath: logsURL.path) {
            FileManager.default.createFile(atPath: logsURL.path, contents: nil)
            appendToLogsFile("=== XSign Logs ===\n")
        }
    }
    
    private func writeLogToFile(_ log: AppLog) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = dateFormatter.string(from: log.timestamp)
        let levelStr = log.level.rawValue.uppercased()
        var logLine = "[\(timestamp)] [\(levelStr)] [\(log.category)] \(log.message)"
        if let details = log.details {
            logLine += " - \(details)"
        }
        logLine += "\n"
        appendToLogsFile(logLine)
    }
    
    private func appendToLogsFile(_ text: String) {
        let logsURL = getLogsFileURL()
        if let data = text.data(using: .utf8) {
            if let fileHandle = try? FileHandle(forWritingTo: logsURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                try? fileHandle.close()
            }
        }
    }
    
    func getLogsFileURL() -> URL {
        let logsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("logs", isDirectory: true)
        
        // Create logs directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: logsDir.path) {
            try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        }
        
        return logsDir.appendingPathComponent(logsFileName)
    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func fetchSignedApps() -> [AppFile] {
        let descriptor = FetchDescriptor<AppFile>(sortBy: [SortDescriptor(\.creationDate, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func fetchLogs() -> [AppLog] {
        let descriptor = FetchDescriptor<AppLog>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func fetchAppFile(by fileName: String) -> AppFile? {
        let descriptor = FetchDescriptor<AppFile>(predicate: #Predicate { $0.fileName == fileName })
        return try? context.fetch(descriptor).first
    }
    
    func createDefaultCategories() {
        let defaultCategories = [
            (name: "IPA Files", icon: "doc.fill", color: "blue"),
            (name: "Dylibs", icon: "curlybraces", color: "purple"),
            (name: "Debs", icon: "square.stack.3d.up.fill", color: "orange"),
            (name: "Signed", icon: "checkmark.seal.fill", color: "green"),
            (name: "Unsigned", icon: "exclamationmark.shield.fill", color: "red")
        ]
        
        for categoryData in defaultCategories {
            if fetchCategory(by: categoryData.name) == nil {
                let category = Category(name: categoryData.name, icon: categoryData.icon, color: categoryData.color)
                context.insert(category)
            }
        }
        save()
    }
    
    func fetchCategory(by name: String) -> Category? {
        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.name == name })
        return try? context.fetch(descriptor).first
    }
}
