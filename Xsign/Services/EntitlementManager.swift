import Foundation

class EntitlementManager {
    static let shared = EntitlementManager()
    private init() {}

    func extractFromProfile(data: Data) -> [String: Any]? {
        guard let profile = ProvisioningParser.shared.parse(data: data) else { return nil }
        return profile.entitlements
    }

    func extractEntitlements(from url: URL) -> [String: Any]? {
        let fileManager = FileManager.default
        let workspace = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        do {
            try fileManager.createDirectory(at: workspace, withIntermediateDirectories: true)
            try ZipService.shared.unzip(at: url, to: workspace)

            let payloadDir = workspace.appendingPathComponent("Payload")
            let contents = try fileManager.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil)
            if let appDir = contents.first(where: { $0.pathExtension == "app" }) {
                let profileURL = appDir.appendingPathComponent("embedded.mobileprovision")
                if let profileData = try? Data(contentsOf: profileURL) {
                    return extractFromProfile(data: profileData)
                }
            }
        } catch {
            print("Entitlement extraction failed: \(error)")
        }
        return nil
    }
}
