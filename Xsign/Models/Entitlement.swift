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

enum CapabilityType: String, Codable, CaseIterable {
    case pushNotifications = "push-notifications"
    case icloud = "icloud"
    case appGroups = "app-groups"
    case networkExtensions = "network-extensions"
    case applePay = "apple-pay"
    case backgroundModes = "background-modes"
    case dataProtection = "data-protection"
    case fileAccess = "file-access"
    case gameCenter = "game-center"
    case healthKit = "health-kit"
    case homeKit = "home-kit"
    case inAppPurchase = "in-app-purchase"
    case keychainAccess = "keychain-access"
    case maps = "maps"
    case personalVPN = "personal-vpn"
    case siri = "siri"
    case wallet = "wallet"
    case wirelessAccessory = "wireless-accessory"
    case custom = "custom"
}
