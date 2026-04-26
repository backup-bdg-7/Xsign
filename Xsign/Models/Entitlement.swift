import Foundation
import SwiftData

@Model
final class Entitlement: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var entitlementDescription: String
    var capabilityType: CapabilityType
    var platform: String
    var isRequired: Bool

    init(id: UUID = UUID(),
         name: String,
         entitlementDescription: String,
         capabilityType: CapabilityType,
         platform: String,
         isRequired: Bool) {
        self.id = id
        self.name = name
        self.entitlementDescription = entitlementDescription
        self.capabilityType = capabilityType
        self.platform = platform
        self.isRequired = isRequired
    }
}

enum CapabilityType: String, Codable {
    case pushNotifications, icloud, appGroups, networkExtensions, other
}
