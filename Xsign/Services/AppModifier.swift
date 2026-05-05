import Foundation
import SwiftData

/**
 * AppModifier handles app modifications like signing, renaming, etc.
 * Based on Feather's AppModifier implementation.
 */
class AppModifier {
    static let shared = AppModifier()
    private init() {}
    
    /// Sign an app file with the given certificate
    func signApp(_ appFile: AppFile, certificate: Certificate) async throws -> URL {
        let size = FileManager.default.fileSize(atPath: appFile.filePath.path) ?? 0
        let type = appFile.type
        
        // Create AppFile for signing
        let newAppFile = AppFile(
            name: appFile.name,
            fileName: appFile.fileName,
            relativePath: appFile.relativePath,
            type: type,
            size: size,
            creationDate: Date()
        )
        
        // Use default options for signing
        let options = SigningOptions(
            ppqProtection: OptionsManager.shared.options.ppqProtection,
            appAppearance: OptionsManager.shared.options.appAppearance,
            minimumAppRequirement: OptionsManager.shared.options.minimumAppRequirement,
            signingOption: OptionsManager.shared.options.signingOption,
            fileSharing: OptionsManager.shared.options.fileSharing,
            itunesFileSharing: OptionsManager.shared.options.itunesFileSharing,
            proMotion: OptionsManager.shared.options.proMotion,
            gameMode: OptionsManager.shared.options.gameMode,
            ipadFullscreen: OptionsManager.shared.options.ipadFullscreen,
            removeURLScheme: OptionsManager.shared.options.removeURLScheme,
            removeProvisioning: OptionsManager.shared.options.removeProvisioning,
            changeLanguageFilesForCustomDisplayName: OptionsManager.shared.options.changeLanguageFilesForCustomDisplayName,
            post_installAppAfterSigned: OptionsManager.shared.options.post_installAppAfterSigned,
            post_deleteAppAfterSigned: OptionsManager.shared.options.post_deleteAppAfterSigned,
            experiment_replaceSubstrateWithEllekit: OptionsManager.shared.options.experiment_replaceSubstrateWithEllekit,
            experiment_supportLiquidGlass: OptionsManager.shared.options.experiment_supportLiquidGlass,
            customBundleID: nil,
            customDisplayName: nil,
            customVersion: nil,
            customBuildVersion: nil,
            customAppIcon: nil,
            entitlements: nil,
            dylibsToInject: nil
        )
        return try await SigningService.shared.sign(appFile: appFile, certificate: certificate, options: options)
    }
}

enum AppModifierError: Error {
    case plistNotFound
    case modificationFailed
    case fileOperationFailed
}
