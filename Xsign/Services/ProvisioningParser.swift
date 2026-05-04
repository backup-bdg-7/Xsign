import Foundation
import Security

/**
 * ProvisioningParser handles .mobileprovision file parsing.
 * Extracts certificates, entitlements, and app ID information.
 */
class ProvisioningParser {
    static let shared = ProvisioningParser()
    private init() {}

    /// Parse a provisioning profile and extract information
    func parse(provisioningProfile: Data) throws -> ProvisioningInfo {
        // Provisioning profiles are DER-encoded with embedded plist
        guard let plistData = extractPlist(from: provisioningProfile) else {
            throw ProvisioningError.invalidFormat
        }

        guard let plist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
            throw ProvisioningError.invalidFormat
        }

        return ProvisioningInfo(from: plist)
    }

    /// Extract the plist data from a provisioning profile
    private func extractPlist(from data: Data) -> Data? {
        // Search for the plist header
        let xmlHeader = "<?xml".data(using: .utf8)!
        let plistHeader = "<plist".data(using: .utf8)!

        if let range = data.range(of: xmlHeader) ?? data.range(of: plistHeader) {
            return data.subdata(in: range.lowerBound..<data.count)
        }

        return nil
    }

    /// Get the embedded certificate from a provisioning profile
    func getCertificate(from provisioningProfile: Data) -> Data? {
        // The certificate is embedded in the provisioning profile
        // Look for the certificate data (DER-encoded)
        // This is a simplified implementation
        return nil
    }
}

/// Information extracted from a provisioning profile
struct ProvisioningInfo {
    let appID: String?
    let teamID: String?
    let bundleID: String?
    let entitlements: [String: Any]?
    let expirationDate: Date?
    let certificates: [Data]?

    init(from plist: [String: Any]) {
        self.appID = plist["AppIDName"] as? String
        self.teamID = (plist["TeamIdentifier"] as? [String])?.first
        
        // Extract bundle ID from entitlements
        if let entitlements = plist["Entitlements"] as? [String: Any] {
            self.entitlements = entitlements
            // Get bundle ID from application-identifier entitlement
            if let appID = entitlements["application-identifier"] as? String {
                // Format is usually "TEAMID.com.example.app"
                let components = appID.split(separator: ".")
                if components.count > 1 {
                    self.bundleID = components.dropFirst().joined(separator: ".")
                } else {
                    self.bundleID = String(appID)
                }
            } else {
                self.bundleID = nil
            }
        } else {
            self.entitlements = nil
            self.bundleID = nil
        }
        
        if let date = plist["ExpirationDate"] as? Date {
            self.expirationDate = date
        } else {
            self.expirationDate = nil
        }

        if let certs = plist["DeveloperCertificates"] as? [Data] {
            self.certificates = certs
        } else {
            self.certificates = nil
        }
    }
}

enum ProvisioningError: Error {
    case invalidFormat
    case missingData
    case parseFailed
}
