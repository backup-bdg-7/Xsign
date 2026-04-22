import Foundation

struct ProvisioningProfile {
    let name: String
    let uuid: String
    let teamIdentifier: String
    let bundleIdentifier: String
    let entitlements: [String: Any]
    let expirationDate: Date
    let certificates: [Data]
}

class ProvisioningParser {
    static let shared = ProvisioningParser()
    private init() {}
    func parse(data: Data) -> ProvisioningProfile? {
        guard let stringContent = String(data: data, encoding: .ascii) else { return nil }
        let scanner = Scanner(string: stringContent)
        var plistString: NSString?
        if scanner.scanUpTo("<plist", into: nil), scanner.scanUpTo("</plist>", into: &plistString) {
            let fullPlist = (plistString! as String) + "</plist>"
            guard let plistData = fullPlist.data(using: .utf8) else { return nil }
            if let dict = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
                return ProvisioningProfile(
                    name: dict["Name"] as? String ?? "",
                    uuid: dict["UUID"] as? String ?? "",
                    teamIdentifier: (dict["TeamIdentifier"] as? [String])?.first ?? "",
                    bundleIdentifier: (dict["Entitlements"] as? [String: Any])?["application-identifier"] as? String ?? "",
                    entitlements: dict["Entitlements"] as? [String: Any] ?? [:],
                    expirationDate: dict["ExpirationDate"] as? Date ?? Date(),
                    certificates: dict["DeveloperCertificates"] as? [Data] ?? []
                )
            }
        }
        return nil
    }
}
