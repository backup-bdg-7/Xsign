import Foundation

class SigningService {
    static let shared = SigningService()
    private init() {}

    func sign(appFile: AppFile, certificate: Certificate, entitlements: [String: Any]? = nil) async throws -> URL {
        await PersistenceService.shared.log(level: .info, category: "Signing", message: "Starting signing for \(appFile.name)")

        // 1. Prepare Workspace
        let workspace = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)

        let ipaPath = appFile.filePath
        let unzipDir = workspace.appendingPathComponent("Payload_Dir")

        // 2. Unzip
        try ZipService.shared.unzip(at: ipaPath, to: unzipDir)

        // 3. Locate App Bundle
        let payload = unzipDir.appendingPathComponent("Payload")
        let contents = try FileManager.default.contentsOfDirectory(at: payload, includingPropertiesForKeys: nil)
        guard let appBundle = contents.first(where: { $0.pathExtension == "app" }) else {
            throw NSError(domain: "Signing", code: 1)
        }

        // 4. Extract and Decrypt Credentials
        let p12Data = try certificate.decryptedP12Data()
        let password = certificate.decryptedPassword() ?? ""
        let p12Path = workspace.appendingPathComponent("cert.p12")
        try p12Data.write(to: p12Path)

        // 5. Replace MobileProvision
        if let profileData = certificate.provisioningProfileData {
            let targetProfile = appBundle.appendingPathComponent("embedded.mobileprovision")
            try? FileManager.default.removeItem(at: targetProfile)
            try profileData.write(to: targetProfile)
        }

        // 6. Call zsign Engine
        let success = ZSignWrapper.signIPA(
            appBundle.path,
            p12: p12Path.path,
            password: password,
            provision: "", // Already replaced
            output: "" // Signing in-place
        )

        if !success { throw NSError(domain: "zsign", code: 2) }

        // 7. Re-zip
        let finalIPA = workspace.appendingPathComponent("signed.ipa")
        try ZipService.shared.zip(directory: unzipDir, to: finalIPA)

        // 8. Update Model
        appFile.isSigned = true
        appFile.signatureStatus = .signed
        appFile.lastSignedDate = Date()
        await PersistenceService.shared.save()

        return finalIPA
    }
}
