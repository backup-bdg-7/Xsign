import Foundation

// MARK: - Signing Options
// Based on Feather's Options model
struct SigningOptions: Codable {
    // PPQ Protection - Appends random string to bundle identifier
    var ppqProtection: Bool = false
    
    // App Appearance options
    var appAppearance: AppAppearance = .default
    
    // Minimum app requirement
    var minimumAppRequirement: MinimumAppRequirement = .default
    
    // Signing type
    var signingOption: SigningOption = .default
    
    // App Features
    var fileSharing: Bool = false
    var itunesFileSharing: Bool = false
    var proMotion: Bool = false
    var gameMode: Bool = false
    var ipadFullscreen: Bool = false
    
    // Removal options
    var removeURLScheme: Bool = false
    var removeProvisioning: Bool = false
    
    // Language/Display
    var changeLanguageFilesForCustomDisplayName: Bool = false
    
    // Post-signing options
    var post_installAppAfterSigned: Bool = false
    var post_deleteAppAfterSigned: Bool = false
    
    // Experiments
    var experiment_replaceSubstrateWithEllekit: Bool = false
    var experiment_supportLiquidGlass: Bool = false
    
    // Custom bundle ID (if PPQ protection is off)
    var customBundleID: String?
    
    // Custom display name
    var customDisplayName: String?
    
    // Custom version
    var customVersion: String?
    var customBuildVersion: String?
    
    // App icon
    var customAppIcon: Data?
    
    // Entitlements
    var entitlements: [String]? // Array of entitlement strings
    
    // Dylibs to inject
    var dylibsToInject: [URL]?
}

// MARK: - App Appearance
enum AppAppearance: String, CaseIterable, Codable {
    case `default` = "Default"
    case light = "Light"
    case dark = "Dark"
    
    var localizedDescription: String {
        return rawValue
    }
}

// MARK: - Minimum App Requirement
enum MinimumAppRequirement: String, CaseIterable, Codable {
    case `default` = "Default"
    case ios12 = "iOS 12"
    case ios13 = "iOS 13"
    case ios14 = "iOS 14"
    case ios15 = "iOS 15"
    case ios16 = "iOS 16"
    case ios17 = "iOS 17"
    
    var localizedDescription: String {
        return rawValue
    }
}

// MARK: - Signing Option
enum SigningOption: String, CaseIterable, Codable {
    case `default` = "Default"
    case adhoc = "Ad-hoc"
    case onlyModify = "Modify Only"
    
    var localizedDescription: String {
        return rawValue
    }
}
