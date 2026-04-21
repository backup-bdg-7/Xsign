import Foundation

class EntitlementManager {
    static let shared = EntitlementManager()
    private init() {}

    /// Extracts entitlements from a certificate's provisioning profile.
    func extractFromProfile(data: Data) -> [String: Any]? {
        guard let profile = ProvisioningParser.shared.parse(data: data) else { return nil }
        return profile.entitlements
    }

    /// Extracts entitlements from an IPA bundle's embedded.mobileprovision.
    func extractFromIPA(at url: URL) -> [String: Any]? {
        let fileManager = FileManager.default
        let workingDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        do {
            try fileManager.createDirectory(at: workingDir, withIntermediateDirectories: true)
            // 1. Unzip to temp
            try ZipService.shared.unzip(at: url, to: workingDir)

            // 2. Find embedded.mobileprovision
            let payloadDir = workingDir.appendingPathComponent("Payload")
            let contents = try fileManager.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil)
            if let appDir = contents.first(where: { $0.pathExtension == "app" }) {
                let profileURL = appDir.appendingPathComponent("embedded.mobileprovision")
                if let profileData = try? Data(contentsOf: profileURL) {
                    return extractFromProfile(data: profileData)
                }
            }
        } catch {
            print("Failed to extract entitlements from IPA: \(error)")
        }

        return nil
    }
}
