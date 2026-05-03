import Foundation

// MARK: - C Function Declarations
// These are implemented in zsign_c_wrapper.cpp in the ZsignC target

/// Sign an iOS app bundle
/// - Parameters:
///   - bundle_path: Path to the .app bundle
///   - certificate_path: Path to the .p12 certificate
///   - password: Password for the certificate
///   - provisioning_profile_path: Path to the .mobileprovision file
///   - output_path: Output path for signed app (can be nil to overwrite)
///   - bundle_id: New bundle ID (can be nil)
///   - display_name: New display name (can be nil)
///   - version: New version (can be nil)
///   - short_version: New short version (can be nil)
///   - adhoc: Sign ad-hoc (no certificate needed)
/// - Returns: True if signing succeeded
@_silgen_name("c_zsign_sign_app")
func c_zsign_sign_app(
    _ bundle_path: UnsafePointer<CChar>,
    _ certificate_path: UnsafePointer<CChar>,
    _ password: UnsafePointer<CChar>,
    _ provisioning_profile_path: UnsafePointer<CChar>,
    _ output_path: UnsafePointer<CChar>?,
    _ bundle_id: UnsafePointer<CChar>?,
    _ display_name: UnsafePointer<CChar>?,
    _ version: UnsafePointer<CChar>?,
    _ short_version: UnsafePointer<CChar>?,
    _ adhoc: Bool
) -> Bool

/// Check certificate validity
/// - Parameters:
///   - certificate_path: Path to the .p12 certificate
///   - password: Password for the certificate
/// - Returns: True if certificate is valid
@_silgen_name("c_zsign_check_certificate")
func c_zsign_check_certificate(
    _ certificate_path: UnsafePointer<CChar>,
    _ password: UnsafePointer<CChar>
) -> Bool

/// Get certificate information as JSON string
/// - Parameters:
///   - certificate_path: Path to the .p12 certificate
///   - password: Password for the certificate
/// - Returns: JSON string with certificate info, or nil if failed
@_silgen_name("c_zsign_get_certificate_info")
func c_zsign_get_certificate_info(
    _ certificate_path: UnsafePointer<CChar>,
    _ password: UnsafePointer<CChar>
) -> UnsafePointer<CChar>?

// MARK: - Zsign Error
public enum ZsignError: Error, LocalizedError {
    case invalidCertificate
    case invalidProvisioningProfile
    case signingFailed(String)
    case invalidBundle
    case certificateNotFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidCertificate:
            return "Invalid certificate"
        case .invalidProvisioningProfile:
            return "Invalid provisioning profile"
        case .signingFailed(let reason):
            return "Signing failed: \(reason)"
        case .invalidBundle:
            return "Invalid bundle"
        case .certificateNotFound:
            return "Certificate not found"
        }
    }
}

// MARK: - Zsign Class
public class Zsign {
    
    public init() {}
    
    /// Sign an iOS app bundle
    /// - Parameters:
    ///   - bundlePath: Path to the .app bundle
    ///   - certificatePath: Path to the .p12 certificate (optional for ad-hoc)
    ///   - password: Password for the certificate
    ///   - provisioningProfilePath: Path to the .mobileprovision file (optional for ad-hoc)
    ///   - outputPath: Output path for signed app (optional, overwrites input if nil)
    ///   - bundleId: New bundle ID (optional)
    ///   - displayName: New display name (optional)
    ///   - version: New version (optional)
    ///   - shortVersion: New short version (optional)
    ///   - adhoc: Sign ad-hoc (no certificate needed)
    /// - Throws: ZsignError if signing fails
    public func signApp(
        bundlePath: String,
        certificatePath: String? = nil,
        password: String? = nil,
        provisioningProfilePath: String? = nil,
        outputPath: String? = nil,
        bundleId: String? = nil,
        displayName: String? = nil,
        version: String? = nil,
        shortVersion: String? = nil,
        adhoc: Bool = false
    ) throws {
        let bundlePathC = bundlePath.cString(using: .utf8)!
        
        let certPathC = certificatePath?.cString(using: .utf8) ?? "".cString(using: .utf8)!
        let passwordC = password?.cString(using: .utf8) ?? "".cString(using: .utf8)!
        let provProfileC = provisioningProfilePath?.cString(using: .utf8) ?? "".cString(using: .utf8)!
        let outputPathC = outputPath?.cString(using: .utf8)
        let bundleIdC = bundleId?.cString(using: .utf8)
        let displayNameC = displayName?.cString(using: .utf8)
        let versionC = version?.cString(using: .utf8)
        let shortVersionC = shortVersion?.cString(using: .utf8)
        
        let result = c_zsign_sign_app(
            bundlePathC,
            certPathC,
            passwordC,
            provProfileC,
            outputPathC,
            bundleIdC,
            displayNameC,
            versionC,
            shortVersionC,
            adhoc
        )
        
        if !result {
            throw ZsignError.signingFailed("Failed to sign app bundle at \(bundlePath)")
        }
    }
    
    /// Check certificate validity
    /// - Parameters:
    ///   - certificatePath: Path to the .p12 certificate
    ///   - password: Password for the certificate
    /// - Returns: True if certificate is valid
    public func checkCertificate(at certificatePath: String, password: String) -> Bool {
        let certPathC = certificatePath.cString(using: .utf8)!
        let passwordC = password.cString(using: .utf8)!
        
        return c_zsign_check_certificate(certPathC, passwordC)
    }
    
    /// Get certificate information
    /// - Parameters:
    ///   - certificatePath: Path to the .p12 certificate
    ///   - password: Password for the certificate
    /// - Returns: Certificate info as JSON string, or nil if failed
    public func getCertificateInfo(at certificatePath: String, password: String) -> String? {
        let certPathC = certificatePath.cString(using: .utf8)!
        let passwordC = password.cString(using: .utf8)!
        
        guard let infoPtr = c_zsign_get_certificate_info(certPathC, passwordC) else {
            return nil
        }
        
        return String(cString: infoPtr)
    }
}
