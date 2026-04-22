import Foundation
import SwiftData

@MainActor
class PersistenceService {
    static let shared = PersistenceService()
    let container: ModelContainer
    private init() {
        let schema = Schema([AppFile.self, Certificate.self, Category.self, Entitlement.self, AppLog.self])
        container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: false)])
    }
    var context: ModelContext { container.mainContext }
    func save() { try? context.save() }
    func log(level: LogLevel, category: String, message: String, details: String? = nil) {
        let log = AppLog(level: level, category: category, message: message, details: details)
        context.insert(log)
        save()
    }
}
