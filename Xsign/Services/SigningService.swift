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
        await PersistenceService.shared.log(level: .info, category: "Signing", message: "Starting signing with Zsign package for \(appFile.name)")
        let p12Data = try certificate.decryptedP12Data()
        let password = certificate.decryptedPassword() ?? ""
        let workspace = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        let p12Path = workspace.appendingPathComponent("cert.p12")
        try p12Data.write(to: p12Path)
        let provisionPath = workspace.appendingPathComponent("embedded.mobileprovision")
        if let profileData = certificate.provisioningProfileData { try profileData.write(to: provisionPath) }
        let outputPath = workspace.appendingPathComponent("signed.ipa")
        let signer = ZSigner()
        if !signer.sign(ipaPath: appFile.filePath.path, p12Path: p12Path.path, password: password, provisionPath: provisionPath.path, bundleId: options.bundleID, bundleName: options.bundleName, bundleVersion: options.bundleVersion, dylibs: options.dylibPaths, outputPath: outputPath.path) {
            throw NSError(domain: "Signing", code: 1)
        }
        appFile.isSigned = true
        appFile.signatureStatus = .signed
        appFile.lastSignedDate = Date()
        await PersistenceService.shared.save()
        return outputPath
    }
}
