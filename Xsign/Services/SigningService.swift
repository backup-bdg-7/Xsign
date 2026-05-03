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
        // 1. Prepare file paths - need to write certificate data to temp files
        let fileManager = FileManager.default
        let tempURL = fileManager.temporaryDirectory
        let appPath = appFile.fileURL.path
        
        // Write P12 data to temp file
        let p12Data = try certificate.decryptedP12Data()
        let p12Path = tempURL.appendingPathComponent("cert.p12")
        try p12Data.write(to: p12Path)
        
        // Write provisioning profile to temp file if available
        var provisionPath = ""
        if let provData = certificate.provisioningProfileData {
            let provURL = tempURL.appendingPathComponent("profile.mobileprovision")
            try provData.write(to: provURL)
            provisionPath = provURL.path
        }
        
        // Get password
        let password = certificate.decryptedPassword() ?? ""

        // 2. Call C function from ZsignC module
        let signSuccess = c_zsign_sign_app(
            appPath,
            p12Path.path,
            password,
            provisionPath.isEmpty ? nil : provisionPath,
            nil, // output_path - use default
            options.bundleID ?? "",
            options.bundleName ?? "",
            options.bundleVersion ?? "",
            nil, // short_version - not used
            false // adhoc
        )

        guard signSuccess else { throw NSError(domain: "Signing", code: 1) }

        // 3. Return signed app path
        let signedPath = URL(fileURLWithPath: appPath).deletingLastPathComponent().appendingPathComponent("signed_\(appFile.fileName)")
        return signedPath
    }
}
