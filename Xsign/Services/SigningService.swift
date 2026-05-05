import Foundation
import ZsignC

/**
 * SigningService handles app signing using Zsign.
 * Based on Feather's ZsignHandler and SigningHandler implementation.
 */
class SigningService {
    static let shared = SigningService()
    private init() {}
    
    /// Sign an app with the given certificate and options
    func sign(appFile: AppFile, certificate: Certificate, options: SigningOptions) async throws -> URL {
        let fileManager = FileManager.default
        let tempURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: tempURL, withIntermediateDirectories: true)
        
        // Get app path
        let appPath = appFile.filePath.path
        let signedAppPath = tempURL.appendingPathComponent("signed_\(appFile.fileName)").path
        
        // Write P12 data to temp file
        let p12Data = try certificate.decryptedP12Data()
        let p12Path = tempURL.appendingPathComponent("cert.p12")
        try p12Data.write(to: p12Path)
        
        // Write provisioning profile to temp file if available
        var provisionPath: String = ""
        if let provData = certificate.provisioningProfileData {
            let provURL = tempURL.appendingPathComponent("profile.mobileprovision")
            try provData.write(to: provURL)
            provisionPath = provURL.path
        }
        
        // Get password
        let password = certificate.decryptedPassword() ?? ""
        
        // Determine bundle ID (apply PPQ protection if enabled)
        var bundleID = options.customBundleID ?? options.customDisplayName ?? appFile.bundleID ?? ""
        if options.ppqProtection {
            // Append random string to bundle ID for PPQ protection
            let randomString = UUID().uuidString.prefix(8).lowercased()
            if !bundleID.isEmpty {
                bundleID = "\(bundleID).\(randomString)"
            } else {
                bundleID = "com.xsign.\(randomString)"
            }
        }
        
        // Determine display name
        let displayName = options.customDisplayName ?? appFile.name
        
        // Determine version
        let version = options.customVersion ?? appFile.version ?? "1.0"
        let buildVersion = options.customBuildVersion ?? appFile.build ?? "1"
        
        // Determine if adhoc
        let adhoc = options.signingOption == .adhoc
        
        // Call C function from ZsignC module
        let signSuccess = c_zsign_sign_app(
            appPath,
            p12Path.path,
            password,
            provisionPath,
            signedAppPath, // output path
            bundleID,
            displayName,
            version,
            buildVersion,
            adhoc
        )
        
        // Clean up temp files
        try? fileManager.removeItem(at: p12Path)
        if !provisionPath.isEmpty {
            try? fileManager.removeItem(at: URL(fileURLWithPath: provisionPath))
        }
        
        guard signSuccess else {
            throw NSError(domain: "Signing", code: 1, userInfo: [NSLocalizedDescriptionKey: "Signing failed"])
        }
        
        // Apply post-signing options
        try applyPostSigningOptions(to: URL(fileURLWithPath: signedAppPath), options: options)
        
        // Return signed app path
        return URL(fileURLWithPath: signedAppPath)
    }
    
    /// Apply post-signing options to the signed app
    private func applyPostSigningOptions(to appURL: URL, options: SigningOptions) throws {
        let fileManager = FileManager.default
        
        if options.post_deleteAppAfterSigned {
            try? fileManager.removeItem(at: appURL)
        }
        
        // TODO: Apply other options like fileSharing, itunesFileSharing, etc.
        // This would require modifying the app bundle's Info.plist
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
        let tempPath = NSTemporaryDirectory() + "signed_app"
        return c_zsign_sign_app(
            appPath,
            "",  // no certificate
            "",  // no password
            "",  // no provisioning profile
            tempPath,  // output path
            "",  // no bundle id change
            "",  // no display name change
            "",  // no version change
            "",  // no short version change
            true  // adhoc
        )
    }
}
