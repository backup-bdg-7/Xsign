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
        let fileManager = FileManager.default
        let tempURL = fileManager.temporaryDirectory
        
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
        
        // Convert dylibPaths to comma-separated string
        let dylibsString = options.dylibPaths?.joined(separator: ",") ?? ""
        
        // Call C function from ZsignC module
        let signSuccess = c_zsign_sign_app(
            appPath,
            p12Path.path,
            password,
            provisionPath ?? "",
            "", // output_path - use empty string instead of nil
            options.bundleID ?? "",
            options.bundleName ?? "",
            options.bundleVersion ?? "",
            options.bundleBuildVersion ?? "",
            "", // dylib_paths - empty for now
            false // adhoc - we have certificate
        )
        
        // Clean up temp files
        try? fileManager.removeItem(at: p12Path)
        if provisionPath != nil {
            try? fileManager.removeItem(at: URL(fileURLWithPath: provisionPath!))
        }
        
        guard signSuccess else { throw NSError(domain: "Signing", code: 1) }
        
        // Return signed app path
        let signedPath = URL(fileURLWithPath: appPath).deletingLastPathComponent().appendingPathComponent("signed_\(appFile.fileName)")
        return signedPath
    }
    
    func checkCertificate(at path: String, password: String) -> Bool {
        return c_zsign_check_certificate(path, password)
    }
    
    func getCertificateInfo(at path: String, password: String) -> String? {
        guard let infoPtr = c_zsign_get_certificate_info(path, password) else {
            return nil
        }
        return String(cString: infoPtr)
    }
}
