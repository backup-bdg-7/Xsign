import Foundation
import ZIPFoundation
import SWCompression
import ZsignC

/// TweakManager handles dylib injection and tweak management.
/// Based on Feather's TweakHandler implementation.
class TweakManager {
    static let shared = TweakManager()
    private let fileManager = FileManager.default
    
    private init() {}
    
    /// Process tweak files (dylib or deb) for injection
    func processTweak(at url: URL, appURL: URL, options: TweakOptions = TweakOptions()) async throws -> [URL] {
        var processedURLs: [URL] = []
        
        switch url.pathExtension.lowercased() {
        case "dylib":
            let processed = try await handleDylib(at: url, appURL: appURL, options: options)
            processedURLs.append(processed)
        case "deb":
            let processed = try await handleDeb(at: url, appURL: appURL)
            processedURLs.append(contentsOf: processed)
        default:
            throw TweakError.unsupportedFileExtension(url.pathExtension)
        }
        
        return processedURLs
    }
    
    /// Handle a dylib file for injection
    private func handleDylib(at url: URL, appURL: URL, options: TweakOptions) async throws -> URL {
        // Just copy the dylib to a temp location
        let tempURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: tempURL, withIntermediateDirectories: true)
        
        let destURL = tempURL.appendingPathComponent(url.lastPathComponent)
        try fileManager.copyItem(at: url, to: destURL)
        
        return destURL
    }
    
    /// Handle a deb file for injection
    private func handleDeb(at url: URL, appURL: URL) async throws -> [URL] {
        // Deb handling is temporarily disabled
        // TODO: Implement proper deb extraction using ar archive format
        throw TweakError.unsupportedFileExtension("deb handling is temporarily disabled")
    }
    
    /// Inject dylibs into all app extensions
    func injectIntoExtensions(appURL: URL, dylibNames: [String], options: TweakOptions) {
        let extensions = discoverAppExtensions(in: appURL)
        
        guard !extensions.isEmpty else { return }
        
        for extURL in extensions {
            for dylibName in dylibNames {
                injectIntoExtension(extensionURL: extURL, dylibName: dylibName, options: options)
            }
        }
    }
    
    /// Discover app extensions (PlugIns and Extensions directories)
    private func discoverAppExtensions(in appURL: URL) -> [URL] {
        var extensions: [URL] = []
        
        let plugInsPath = appURL.appendingPathComponent("PlugIns")
        let extensionsPath = appURL.appendingPathComponent("Extensions")
        
        for directory in [plugInsPath, extensionsPath] {
            guard fileManager.fileExists(atPath: directory.path) else { continue }
            
            do {
                let contents = try fileManager.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                )
                
                let appexFiles = contents.filter { url in
                    url.pathExtension.lowercased() == "appex" && url.hasDirectoryPath
                }
                
                extensions.append(contentsOf: appexFiles)
            } catch {
                print("Failed to enumerate \(directory.path): \(error.localizedDescription)")
            }
        }
        
        return extensions
    }
    
    /// Inject a dylib into an extension
    private func injectIntoExtension(extensionURL: URL, dylibName: String, options: TweakOptions) {
        guard
            let extBundle = Bundle(url: extensionURL),
            let extExecutable = extBundle.executableURL
        else {
            print("Skipping \(extensionURL.lastPathComponent): couldn't read bundle")
            return
        }
        
        var injectFolder = options.injectFolder
        if options.injectPath == .rpath && options.injectFolder == .frameworks {
            injectFolder = .root
        }
        
        let injectPath: String
        switch injectFolder {
        case .root:
            injectPath = ""
        case .frameworks:
            injectPath = "Frameworks/"
        }
        
        let dylibPath = "\(injectPath)\(dylibName)"
        let fullDylibPath = options.injectPath.rawValue + dylibPath
        
        // Use zsign C function to inject the dylib
        let success = c_zsign_inject_dylib(
            extExecutable.path,
            (fullDylibPath as NSString).utf8String!
        )
        
        if success {
            print("Injected \(dylibName) into \(extensionURL.lastPathComponent)")
        } else {
            print("Failed to inject \(dylibName) into \(extensionURL.lastPathComponent)")
        }
    }
}

struct TweakOptions {
    var injectPath: InjectPath = .rpath
    var injectFolder: InjectFolder = .frameworks
    var injectIntoExtensions: Bool = false
    
    enum InjectPath: String {
        case rpath = "@rpath/"
        case executablePath = "@executable_path/"
    }
    
    enum InjectFolder: String {
        case root = "/"
        case frameworks = "Frameworks/"
    }
}

enum TweakError: Error {
    case unsupportedFileExtension(String)
    case decompressionFailed(String)
    case missingFile(String)
    case noAccess
}

// MARK: - C Function Declarations
@_silgen_name("c_zsign_inject_dylib")
func c_zsign_inject_dylib(_ appExecutable: UnsafePointer<CChar>, _ dylibPath: UnsafePointer<CChar>) -> Bool

@_silgen_name("c_zsign_change_dylib_path")
func c_zsign_change_dylib_path(_ dylibPath: UnsafePointer<CChar>, _ oldPath: UnsafePointer<CChar>, _ newPath: UnsafePointer<CChar>) -> Bool
