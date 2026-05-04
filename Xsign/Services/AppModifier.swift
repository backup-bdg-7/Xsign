import Foundation
import ZsignC

/**
 * AppModifier handles app bundle modifications.
 * Based on Feather's approach for modifying app properties.
 */
class AppModifier {
    static let shared = AppModifier()
    private init() {}

    /// Modify an app's Info.plist with new properties
    func modifyInfoPlist(appURL: URL, properties: [String: Any]) throws {
        let infoPlistURL = appURL.appendingPathComponent("Info.plist")

        guard FileManager.default.fileExists(atPath: infoPlistURL.path) else {
            throw AppModifierError.plistNotFound
        }

        guard let plist = try NSMutableDictionary(contentsOf: infoPlistURL) else {
            throw NSError(domain: "AppModifier", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to read Info.plist"])
        }

        for (key, value) in properties {
            plist[key] = value
        }

        try plist.write(to: infoPlistURL)
    }

    /// Change an app's bundle ID
    func changeBundleID(appURL: URL, newBundleID: String) throws {
        try modifyInfoPlist(appURL: appURL, properties: ["CFBundleIdentifier": newBundleID])
    }

    /// Change an app's display name
    func changeDisplayName(appURL: URL, newName: String) throws {
        try modifyInfoPlist(appURL: appURL, properties: ["CFBundleDisplayName": newName])
    }

    /// Change an app's version
    func changeVersion(appURL: URL, newVersion: String) throws {
        try modifyInfoPlist(appURL: appURL, properties: ["CFBundleVersion": newVersion])
    }

    /// Change an app's short version
    func changeShortVersion(appURL: URL, newVersion: String) throws {
        try modifyInfoPlist(appURL: appURL, properties: ["CFBundleShortVersionString": newVersion])
    }

    /// Remove files from an app bundle
    func removeFiles(from appURL: URL, fileNames: [String]) throws {
        let fileManager = FileManager.default

        for fileName in fileNames {
            let fileURL = appURL.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        }
    }

    /// Add a file to an app bundle
    func addFile(to appURL: URL, fileURL: URL, destinationPath: String? = nil) throws {
        let fileName = destinationPath ?? fileURL.lastPathComponent
        let destinationURL = appURL.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: fileURL, to: destinationURL)
    }

    /// Resign an app with zsign (after modifications)
    func resignApp(at appURL: URL, certificate: Certificate) async throws -> URL {
        // This is a wrapper around SigningService
        // Just call SigningService.shared.sign with appropriate options
        let options = SigningService.SigningOptions()
        return try await SigningService.shared.sign(appFile: AppFile(filePath: appURL), certificate: certificate, options: options)
    }
}

enum AppModifierError: Error {
    case plistNotFound
    case modificationFailed
    case fileOperationFailed
}
