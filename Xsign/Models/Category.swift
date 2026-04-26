import Foundation

final class Category: Identifiable {
    var id: UUID
    var name: String
    var icon: String
    var color: String
    var appFiles: [AppFile]? = []

    init(id: UUID = UUID(), name: String, icon: String, color: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
    }
}
