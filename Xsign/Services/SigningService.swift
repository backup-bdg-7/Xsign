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
    }

    func sign(appFile: AppFile, certificate: Certificate, options: SigningOptions) async throws -> URL {
        // 1. Prepare file paths
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let appPath = documentsURL.appendingPathComponent(appFile.fileName)
        let p12Path = documentsURL.appendingPathComponent(certificate.fileName)
        let provisionPath = documentsURL.appendingPathComponent(certificate.provisionFileName ?? "")
        let entitlementsPath = documentsURL.appendingPathComponent("entitlements.plist")

        // 2. Extract certificate password
        let password = certificate.password ?? ""

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

        guard signSuccess else { throw NSError(domain: "Signing", code: 1) }

        // 4. Return signed app path (simplified - need to handle IPA creation)
        let signedPath = appPath.deletingLastPathComponent().appendingPathComponent("signed_\(appFile.fileName)")
        return signedPath
    }
}
