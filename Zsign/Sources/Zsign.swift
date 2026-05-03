// Zsign.swift - Swift wrapper for Zsign C library

import Foundation
import ZsignC

public class Zsign {
    public static func sign(
        appPath: String,
        provisionPath: String,
        p12Path: String,
        p12Password: String,
        entitlementsPath: String,
        customIdentifier: String,
        customName: String,
        customVersion: String,
        adhoc: Bool,
        removeProvision: Bool,
        completion: @escaping (Bool) -> Void
    ) -> Bool {
        let result = c_zsign_sign_app(
            appPath,
            p12Path,
            p12Password,
            provisionPath.isEmpty ? nil : provisionPath,
            nil, // output_path - not used
            customIdentifier.isEmpty ? nil : customIdentifier,
            customName.isEmpty ? nil : customName,
            customVersion.isEmpty ? nil : customVersion,
            nil, // short_version - not used
            adhoc
        )
        
        completion(result)
        return result
    }
}
