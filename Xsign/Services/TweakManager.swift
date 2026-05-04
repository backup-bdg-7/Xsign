import Foundation
import ZIPFoundation
import SWCompression
import ZsignC

/**
 * TweakManager handles dylib injection and tweak management.
 * Based on Feather's TweakHandler implementation.
 */
class TweakManager {
    static let shared = TweakManager()
    private let fileManager = FileManager.default
    private var injectedDylibNames: [String] = []

    private init() {}

    /// Process tweak files (dylib or deb) for injection
    func processTweak(at url: URL, appURL: URL, options: TweakOptions = .default) async throws -> [URL] {
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
        var destinationURL = appURL
        let injectFolder = options.injectFolder

        // Check for Frameworks folder
        if injectFolder == .frameworks {
            destinationURL = destinationURL.appendingPathComponent("Frameworks")
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        }

        destinationURL = destinationURL.appendingPathComponent(url.lastPathComponent)

        // Copy dylib to app
        try fileManager.copyItem(at: url, to: destinationURL)

        // Change dylib paths if needed (for CydiaSubstrate compatibility)
        if fileManager.fileExists(atPath: destinationURL.path) {
            _ = c_zsign_change_dylib_path(
                destinationURL.path,
                "/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate",
                "@rpath/CydiaSubstrate.framework/CydiaSubstrate"
            )
        }

        // Inject into main executable
        if let appexe = Bundle(url: appURL)?.executableURL {
            let injectPath = "\(options.injectPath.rawValue)\(injectFolder.rawValue)\(destinationURL.lastPathComponent)"
            _ = c_zsign_inject_dylib(appexe.path, injectPath)
        }

        injectedDylibNames.append(destinationURL.lastPathComponent)

        return destinationURL
    }

    /// Handle a deb file for injection
    private func handleDeb(at url: URL, appURL: URL) async throws -> [URL] {
        let baseTmpDir = fileManager.temporaryDirectory
            .appendingPathComponent("TweakManager_\(UUID().uuidString)")
        try fileManager.createDirectory(at: baseTmpDir, withIntermediateDirectories: true)

        // Parse deb file
        let data = try Data(contentsOf: url)
        guard let archive = ArArchive(data: data) else {
            throw TweakError.decompressionFailed("Failed to parse deb file")
        }

        var processedURLs: [URL] = []

        for entry in archive.entries where entry.name.hasPrefix("data.tar") {
            var tarData = entry.data

            // Decompress if needed
            if entry.name.hasSuffix(".gz") {
                tarData = try GzipArchive.unarchive(archive: tarData)
            } else if entry.name.hasSuffix(".xz") {
                tarData = try XZArchive.unarchive(archive: tarData)
            } else if entry.name.hasSuffix(".bz2") {
                tarData = try BZip2.decompress(data: tarData)
            }

            // Parse tar archive
            let tar = try TarContainer.open(container: tarData)

            // Process entries
            for entry in tar {
                let name = entry.info.name
                guard let data = entry.data else { continue }

                // Check for dylibs, frameworks, or bundles
                if name.hasSuffix(".dylib") {
                    let destURL = baseTmpDir.appendingPathComponent(URL(fileURLWithPath: name).lastPathComponent)
                    try data.write(to: destURL)
                    processedURLs.append(destURL)
                } else if name.hasSuffix(".framework/") || name.hasSuffix(".framework") {
                    // Handle framework
                    let frameworkURL = baseTmpDir.appendingPathComponent(URL(fileURLWithPath: name).lastPathComponent)
                    try fileManager.createDirectory(at: frameworkURL, withIntermediateDirectories: true)
                } else if name.hasSuffix(".bundle/") || name.hasSuffix(".bundle") {
                    // Handle bundle
                    let bundleURL = baseTmpDir.appendingPathComponent(URL(fileURLWithPath: name).lastPathComponent)
                    try fileManager.createDirectory(at: bundleURL, withIntermediateDirectories: true)
                }
            }
        }

        return processedURLs
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
        if options.injectPath == .rpath {
            injectPath = "@rpath/\(dylibName)"
        } else {
            if injectFolder == .frameworks {
                injectPath = "@executable_path/../../Frameworks/\(dylibName)"
            } else {
                injectPath = "@executable_path/../../\(dylibName)"
            }
        }

        let success = c_zsign_inject_dylib(extExecutable.path, injectPath)

        if success {
            print("Injected \(dylibName) into extension: \(extensionURL.lastPathComponent)")
        } else {
            print("Failed to inject into extension: \(extensionURL.lastPathComponent)")
        }
    }
}

// MARK: - Options and Errors
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
