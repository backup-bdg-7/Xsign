import Foundation
import Zsign

/**
 * SigningService orchestrates the production-grade signing process using the Zsign engine.
 * It manages temporary workspaces and handles IPA/Binary modification.
 */
class SigningService {
    static let shared = SigningService()
    private init() {}

    struct SigningOptions {
        var bundleID: String?
        var bundleName: String?
        var bundleVersion: String?
        var dylibPaths: [String]?
        var entitlementsPath: String?
    }

    /**
     * Signs an application bundle with the provided certificate and options.
     */
    func sign(appFile: AppFile, certificate: Certificate, options: SigningOptions) async throws -> URL {
        await PersistenceService.shared.log(level: .info, category: "Signing", message: "Starting production sign for \(appFile.name)")

        // 1. Workspace Setup
        let workspace = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)

        // 2. Decrypt Credentials
        let p12Data = try certificate.decryptedP12Data()
        let password = certificate.decryptedPassword() ?? ""

        let p12Path = workspace.appendingPathComponent("cert.p12")
        try p12Data.write(to: p12Path)

        let provisionPath = workspace.appendingPathComponent("embedded.mobileprovision")
        if let profileData = certificate.provisioningProfileData {
            try profileData.write(to: provisionPath)
        }

        let outputPath = workspace.appendingPathComponent("signed_\(appFile.fileName)")

        // 3. Invoke Zsign Package
        let signer = ZSigner()
        let success = signer.sign(
            ipaPath: appFile.filePath.path,
            p12Path: p12Path.path,
            password: password,
            provisionPath: provisionPath.path,
            bundleId: options.bundleID,
            bundleName: options.bundleName,
            bundleVersion: options.bundleVersion,
            dylibs: options.dylibPaths,
            entitlements: options.entitlementsPath,
            outputPath: outputPath.path
        )

        if !success {
            await PersistenceService.shared.log(level: .error, category: "Signing", message: "Zsign execution failed for \(appFile.name)")
            throw NSError(domain: "SigningService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Signing engine failure"])
        }

        // 4. Update Model State
        appFile.isSigned = true
        appFile.signatureStatus = .signed
        appFile.lastSignedDate = Date()
        await PersistenceService.shared.save()

        await PersistenceService.shared.log(level: .success, category: "Signing", message: "Successfully signed \(appFile.name)")

        return outputPath
    }
}
