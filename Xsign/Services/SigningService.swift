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
        var entitlements: String? // XML plist content
    }

    func sign(appFile: AppFile, certificate: Certificate, options: SigningOptions) async throws -> URL {
        let p12Data = try certificate.decryptedP12Data()
        let password = certificate.decryptedPassword() ?? ""

        let workspace = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)

        // 1. Prepare Credentials
        let p12Path = workspace.appendingPathComponent("cert.p12")
        try p12Data.write(to: p12Path)

        let provisionPath = workspace.appendingPathComponent("embedded.mobileprovision")
        if let profileData = certificate.provisioningProfileData {
            try profileData.write(to: provisionPath)
        }

        // 2. Prepare Entitlements if provided
        var entitlementsPath: String? = nil
        if let entitlementsData = options.entitlements {
            let path = workspace.appendingPathComponent("entitlements.plist")
            try entitlementsData.write(to: path, atomically: true, encoding: .utf8)
            entitlementsPath = path.path
        }

        // 3. Extract IPA for folder-based signing
        let unzipDir = workspace.appendingPathComponent("AppPayload")
        try ZipService.shared.unzip(at: appFile.filePath, to: unzipDir)

        // Find the .app folder
        let appPath = unzipDir.appendingPathComponent("Payload").appendingPathComponent("\(appFile.fileName).app")

        let outputPath = workspace.appendingPathComponent("signed_\(appFile.fileName)")

        // 4. Sign using Zsign Swift package
        let signSuccess = Zsign.sign(
            appPath: appPath.path,
            provisionPath: provisionPath.path,
            p12Path: p12Path.path,
            p12Password: password,
            entitlementsPath: entitlementsPath ?? "",
            customIdentifier: options.bundleID ?? "",
            customName: options.bundleName ?? "",
            customVersion: options.bundleVersion ?? "",
            adhoc: false,
            removeProvision: false
        ) { success in
            print("[ZSign] Signing completion: \(success)")
        }

        guard signSuccess else { throw NSError(domain: "Signing", code: 1) }

        // 5. Repackage signed folder into IPA
        let ipaOutputPath = outputPath.appendingPathExtension("ipa")
        // TODO: Implement IPA creation from signed .app folder

        appFile.isSigned = true
        appFile.signatureStatus = .signed
        appFile.lastSignedDate = Date()
        await PersistenceService.shared.save()

        return ipaOutputPath as URL
    }
}
