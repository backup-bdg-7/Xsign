import Foundation

enum LogLevel: String, Codable {
    case info, success, warning, error
}

final class AppLog: Identifiable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var level: LogLevel
    var category: String
    var message: String
    var details: String?

    init(id: UUID = UUID(), timestamp: Date = Date(), level: LogLevel, category: String, message: String, details: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.details = details
    }
}
