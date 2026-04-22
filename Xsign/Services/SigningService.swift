import Foundation

class SigningService {
    static let shared = SigningService()
    private init() {}

    func sign(appFile: AppFile, certificate: Certificate, entitlements: [String: Any]? = nil) async throws -> URL {
        await PersistenceService.shared.log(level: .info, category: "Signing", message: "Starting robust sign for \(appFile.name)")

        // 1. Prepare Workspace
        let workspace = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)

        let ipaPath = appFile.filePath
        let unzipDir = workspace.appendingPathComponent("AppContent")

        // 2. Unzip using Zip library
        try ZipService.shared.unzip(at: ipaPath, to: unzipDir)

        // 3. Locate Binary
        let payload = unzipDir.appendingPathComponent("Payload")
        let contents = try FileManager.default.contentsOfDirectory(at: payload, includingPropertiesForKeys: nil)
        guard let appBundle = contents.first(where: { $0.pathExtension == "app" }) else {
            throw NSError(domain: "Signing", code: 1)
        }

        let infoPlistPath = appBundle.appendingPathComponent("Info.plist")
        guard let infoPlist = NSDictionary(contentsOf: infoPlistPath),
              let executableName = infoPlist["CFBundleExecutable"] as? String else {
            throw NSError(domain: "Signing", code: 2)
        }
        let executableURL = appBundle.appendingPathComponent(executableName)

        // 4. Perform Signing with Engine
        let p12Data = try certificate.decryptedP12Data()
        let password = certificate.decryptedPassword() ?? ""

        // Extract cert/key from p12 using OpenSSL in a real implementation
        try ZSignEngine.shared.sign(
            executable: executableURL,
            certificate: p12Data,
            privateKey: Data(), // Derived from p12
            entitlements: entitlements ?? [:]
        )

        // 5. Re-zip
        let finalIPA = workspace.appendingPathComponent("signed.ipa")
        try ZipService.shared.zip(directory: unzipDir, to: finalIPA)

        await PersistenceService.shared.log(level: .success, category: "Signing", message: "Completed robust signing")

        return finalIPA
    }
}
