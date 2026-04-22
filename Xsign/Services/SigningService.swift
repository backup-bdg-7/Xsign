import Foundation
import Zsign

class SigningService {
    static let shared = SigningService()
    private init() {}

    struct SigningOptions {
        var bundleID: String?
        var bundleName: String?
        var bundleVersion: String?
        var dylibPaths: [String]?
    }

    func sign(appFile: AppFile, certificate: Certificate, options: SigningOptions) async throws -> URL {
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

        let outputPath = workspace.appendingPathComponent("signed_\(appFile.fileName)")

        // Final Bridge call to ZSign engine
        let success = ZSignWrapper.signIPA(
            appFile.filePath.path,
            p12: p12Path.path,
            password: password,
            provision: provisionPath.path,
            bundleID: options.bundleID,
            bundleName: options.bundleName,
            bundleVersion: options.bundleVersion,
            dylibs: options.dylibPaths ?? [],
            output: outputPath.path
        )

        guard success else { throw NSError(domain: "Signing", code: 1) }

        appFile.isSigned = true
        appFile.signatureStatus = .signed
        appFile.lastSignedDate = Date()
        await PersistenceService.shared.save()

        return outputPath
    }
}
