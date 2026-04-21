import Foundation
import SwiftData

@MainActor
class PersistenceService {
    static let shared = PersistenceService()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            AppFile.self,
            Certificate.self,
            Category.self,
            Entitlement.self,
            AppLog.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var context: ModelContext {
        container.mainContext
    }

    func save() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }

    func log(level: LogLevel, category: String, message: String, details: String? = nil) {
        let log = AppLog(level: level, category: category, message: message, details: details)
        context.insert(log)
        save()
    }
}
