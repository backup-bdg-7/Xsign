import Foundation

class SigningService {
    static let shared = SigningService()
    private init() {}

    func sign(appFile: AppFile, certificate: Certificate, entitlements: [String: Any]? = nil) async throws -> URL {
        await PersistenceService.shared.log(level: .info, category: "Signing", message: "Starting zsign for \(appFile.name)")

        let p12Data = try certificate.decryptedP12Data()
        let password = certificate.decryptedPassword() ?? ""

        let workspace = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)

        let p12Path = workspace.appendingPathComponent("cert.p12")
        try p12Data.write(to: p12Path)

        let provisionPath = workspace.appendingPathComponent("embedded.mobileprovision")
        if let profileData = certificate.provisioningProfileData {
            try profileData.write(to: provisionPath)
        }

        let outputPath = workspace.appendingPathComponent("signed.ipa")

        // Execute the zsign engine through the wrapper
        let success = ZSignWrapper.signIPA(
            appFile.filePath.path,
            p12: p12Path.path,
            password: password,
            provision: provisionPath.path,
            output: outputPath.path
        )

        if !success {
            await PersistenceService.shared.log(level: .error, category: "Signing", message: "zsign engine failed")
            throw NSError(domain: "SigningService", code: 1, userInfo: [NSLocalizedDescriptionKey: "zsign execution failed"])
        }

        await PersistenceService.shared.log(level: .success, category: "Signing", message: "Successfully signed \(appFile.name)")

        appFile.isSigned = true
        appFile.signatureStatus = .signed
        appFile.lastSignedDate = Date()
        await PersistenceService.shared.save()

        return outputPath
    }
}
