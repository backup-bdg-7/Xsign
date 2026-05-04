import Foundation
import ZsignC

/**
 * SigningService handles app signing using Zsign.
 * Based on Feather's ZsignHandler and SigningHandler implementation.
 */
class SigningService {
    static let shared = SigningService()
    private init() {}

    struct SigningOptions {
        var bundleID: String?
        var bundleName: String?
        var bundleVersion: String?
        var bundleBuildVersion: String?
        var appIcon: Data?
        var removeFiles: [String]?
        var injectDylibs: [URL]?
        var entitlementsURL: URL?
        var signingOption: SigningOption = .default
    }

    enum SigningOption {
        case `default`
        case adhoc
        case onlyModify
    }

    /// Sign an app with the given certificate and options
    func sign(appFile: AppFile, certificate: Certificate, options: SigningOptions) async throws -> URL {
        let fileManager = FileManager.default
        let tempURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: tempURL, withIntermediateDirectories: true)

        // Get app file path
        let appPath = appFile.filePath.path

        // Write P12 data to temp file
        let p12Data = try certificate.decryptedP12Data()
        let p12Path = tempURL.appendingPathComponent("cert.p12")
        try p12Data.write(to: p12Path)

        // Write provisioning profile to temp file if available
        var provisionPath: String? = nil
        if let provData = certificate.provisioningProfileData {
            let provURL = tempURL.appendingPathComponent("profile.mobileprovision")
            try provData.write(to: provURL)
            provisionPath = provURL.path
        }

        // Get password
        let password = certificate.decryptedPassword() ?? ""

        // Get entitlements path
        let entitlementsPath = options.entitlementsURL?.path ?? ""

        // Convert dylib paths to comma-separated string
        let dylibsString = options.injectDylibs?
            .map { $0.path }
            .joined(separator: ",") ?? ""

        // Determine if adhoc
        let adhoc = options.signingOption == .adhoc

        // Call C function from ZsignC module
        let signSuccess = c_zsign_sign_app(
            appPath,
            p12Path.path,
            password,
            provisionPath ?? "",
            entitlementsPath,
            options.bundleID ?? "",
            options.bundleName ?? "",
            options.bundleVersion ?? "",
            options.bundleBuildVersion ?? "",
            adhoc
        )

        // Clean up temp files
        try? fileManager.removeItem(at: p12Path)
        if provisionPath != nil {
            try? fileManager.removeItem(at: URL(fileURLWithPath: provisionPath!))
        }

        guard signSuccess else {
            throw NSError(domain: "Signing", code: 1, userInfo: [NSLocalizedDescriptionKey: "Signing failed"])
        }

        // Return signed app path
        let signedPath = URL(fileURLWithPath: appPath).deletingLastPathComponent().appendingPathComponent("signed_\(appFile.fileName)")
        return signedPath
    }

    /// Check if a certificate is valid
    func checkCertificate(at path: String, password: String) -> Bool {
        return c_zsign_check_certificate(path, password)
    }

    /// Get certificate info
    func getCertificateInfo(at path: String, password: String) -> String? {
        guard let infoPtr = c_zsign_get_certificate_info(path, password) else {
            return nil
        }
        return String(cString: infoPtr)
    }

    /// Ad-hoc sign an app (no certificate needed)
    func adhocSign(appPath: String, entitlementsPath: String?) -> Bool {
        return c_zsign_sign_app(
            appPath,
            "",
            "",
            "",
            entitlementsPath ?? "",
            "",
            "",
            "",
            "",
            true
        )
    }
}

// MARK: - C Function Declarations
@_silgen_name("c_zsign_sign_app")
func c_zsign_sign_app(
    _ bundle_path: UnsafePointer<CChar>,
    _ certificate_path: UnsafePointer<CChar>,
    _ password: UnsafePointer<CChar>,
    _ provisioning_profile_path: UnsafePointer<CChar>,
    _ output_path: UnsafePointer<CChar>,
    _ bundle_id: UnsafePointer<CChar>,
    _ display_name: UnsafePointer<CChar>,
    _ version: UnsafePointer<CChar>,
    _ short_version: UnsafePointer<CChar>,
    _ adhoc: Bool
) -> Bool

@_silgen_name("c_zsign_check_certificate")
func c_zsign_check_certificate(_ certificate_path: UnsafePointer<CChar>, _ password: UnsafePointer<CChar>) -> Bool

@_silgen_name("c_zsign_get_certificate_info")
func c_zsign_get_certificate_info(_ certificate_path: UnsafePointer<CChar>, _ password: UnsafePointer<CChar>) -> UnsafePointer<CChar>?
