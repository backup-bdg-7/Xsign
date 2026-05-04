import Foundation
import Security

/**
 * EntitlementManager handles app entitlements.
 * Based on Feather's approach - load from file or generate default.
 */
class EntitlementManager {
    static let shared = EntitlementManager()
    private init() {}

    /// Load entitlements from a file URL
    func loadEntitlements(from url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            throw EntitlementError.invalidFormat
        }
        return plist
    }

    /// Generate default entitlements for an app
    func generateDefaultEntitlements(appID: String, teamID: String? = nil) -> [String: Any] {
        var entitlements: [String: Any] = [:]

        // Basic entitlements
        entitlements["application-identifier"] = appID
        entitlements["get-task-allow"] = true

        if let teamID = teamID {
            entitlements["com.apple.developer.team-identifier"] = teamID
        }

        // Common entitlements for tweaked apps
        entitlements["com.apple.security.application-groups"] = ["group.\(appID)"]
        entitlements["com.apple.developer.networking.multicast"] = true

        return entitlements
    }

    /// Save entitlements to a file
    func saveEntitlements(_ entitlements: [String: Any], to url: URL) throws {
        let data = try PropertyListSerialization.data(fromPropertyList: entitlements, format: .xml, options: 0)
        try data.write(to: url)
    }

    /// Get entitlements from a provisioning profile
    func extractEntitlements(from provisioningProfile: Data) -> [String: Any]? {
        // Provisioning profiles are DER-encoded
        // We need to find the entitlements plist inside
        guard let plistData = extractPlist(from: provisioningProfile) else {
            return nil
        }

        return try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any]
    }

    private func extractPlist(from data: Data) -> Data? {
        // Simple search for <?xml tag
        let xmlHeader = "<?xml".data(using: .utf8)!
        let plistHeader = "<plist".data(using: .utf8)!

        if let range = data.range(of: xmlHeader) ?? data.range(of: plistHeader) {
            return data.subdata(in: range.lowerBound..<data.count)
        }

        return nil
    }
}

enum EntitlementError: Error {
    case invalidFormat
    case fileNotFound
    case writeFailed
}
