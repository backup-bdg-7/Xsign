import Foundation
import SwiftData

@Model
final class Category: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var color: String
    @Relationship(deleteRule: .nullify, inverse: \AppFile.category)
    var appFiles: [AppFile]? = []

    init(id: UUID = UUID(), name: String, icon: String, color: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
    }
}
