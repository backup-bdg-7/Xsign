import Foundation
import ZsignC

class SigningService {
    static let shared = SigningService()
    private init() {}

    struct SigningOptions {
        var bundleID: String?
        var bundleName: String?
        var bundleVersion: String?
        var bundleBuildVersion: String?
        var dylibPaths: [String]?
    }

    func sign(appFile: AppFile, certificate: Certificate, options: SigningOptions) async throws -> URL {
        // 1. Prepare file paths
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Get app file path
        let appPath = documentsURL.appendingPathComponent(appFile.fileName)
        
        // Decrypt and write P12 file
        let p12Data = try certificate.decryptedP12Data()
        let p12Path = documentsURL.appendingPathComponent("temp_cert.p12")
        try p12Data.write(to: p12Path)
        
        // Write provisioning profile if available
        let provisionPath = documentsURL.appendingPathComponent("temp.mobileprovision")
        if let provisionData = certificate.provisioningProfileData {
            try provisionData.write(to: provisionPath)
        }
        
        let entitlementsPath = documentsURL.appendingPathComponent("entitlements.plist")
        
        // 2. Get certificate password
        let password = certificate.decryptedPassword() ?? ""
        
        // 3. Call C function from ZsignC module
        let signSuccess = c_zsign_sign_app(
            appPath.path,
            p12Path.path,
            password,
            provisionPath.path,
            nil, // output_path - use default
            options.bundleID ?? "",
            options.bundleName ?? "",
            options.bundleVersion ?? "",
            nil, // short_version - not used
            false // adhoc
        )
        
        // Clean up temp files
        try? fileManager.removeItem(at: p12Path)
        if certificate.provisioningProfileData != nil {
            try? fileManager.removeItem(at: provisionPath)
        }
        
        guard signSuccess else { throw NSError(domain: "Signing", code: 1) }
        
        // 4. Return signed app path (simplified - need to handle IPA creation)
        let signedPath = appPath.deletingLastPathComponent().appendingPathComponent("signed_\(appFile.fileName)")
        return signedPath
    }
}
