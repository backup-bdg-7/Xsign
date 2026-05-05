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
    // Core Certificate Entitlements
    case applicationIdentifier = "application-identifier"
    case keychainAccessGroups = "keychain-access-groups"
    case getTaskAllow = "get-task-allow"
    case teamIdentifier = "team-identifier"
    
    // App Services
    case pushNotifications = "push-notifications"
    case applePay = "apple-pay"
    case appGroups = "app-groups"
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
    
    // Networking
    case networkExtensions = "network-extensions"
    case hotspotHelper = "hotspot-helper"
    case multipath = "multipath"
    case vpnConfiguration = "vpn-configuration"
    
    // Hardware
    case nfc = "nfc"
    case camera = "camera"
    case microphone = "microphone"
    case bluetooth = "bluetooth"
    case externalAccessory = "external-accessory"
    
    // Security
    case sharedPassword = "shared-password"
    case associatedDomains = "associated-domains"
    
    // Media
    case mediaLibrary = "media-library"
    case musicRecognition = "music-recognition"
    case photoLibrary = "photo-library"
    case videoSubscriber = "video-subscriber"
    
    // Communication
    case callKit = "call-kit"
    case messageFilter = "message-filter"
    case contacts = "contacts"
    
    // iCloud
    case icloud = "icloud"
    case ubiquityContainer = "ubiquity-container"
    case ubiquityKVStore = "ubiquity-kvstore"
}
