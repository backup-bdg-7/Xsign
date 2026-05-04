import Foundation
import ZsignC

/**
 * BinaryParser performs deep analysis of Mach-O files.
 * Uses Zsign's Mach-O parsing capabilities via C wrapper.
 * Similar to how Feather parses binaries for dylib information.
 */
class BinaryParser {
    static let shared = BinaryParser()
    private init() {}

    /// Extracts a list of linked dylibs from a Mach-O file (Universal or Thin).
    /// Uses Zsign's Mach-O parsing for accurate results.
    func getDylibs(at url: URL) -> [String] {
        guard let path = url.path.cString(using: .utf8) else { return [] }

        // Call C function from ZsignC module
        guard let dylibsPtr = c_zsign_get_dylibs(path) else { return [] }
        let dylibsString = String(cString: dylibsPtr)

        // Parse the returned string (comma-separated list)
        if dylibsString.isEmpty || dylibsString == "none" {
            return []
        }

        return dylibsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    /// Get metadata from an app bundle
    func getMetadata(appFolder: URL, outputDir: URL, ipaFile: URL? = nil) -> [String: Any]? {
        guard let appPath = appFolder.path.cString(using: .utf8),
              let outputPath = outputDir.path.cString(using: .utf8) else { return nil }

        let ipaPath = ipaFile?.path.cString(using: .utf8) ?? ""

        guard let metadataPtr = c_zsign_get_metadata(appPath, outputPath, ipaPath) else { return nil }
        let metadataString = String(cString: metadataPtr)

        // Parse JSON metadata
        guard let data = metadataString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return json
    }
}

// MARK: - C Function Declarations
@_silgen_name("c_zsign_get_dylibs")
func c_zsign_get_dylibs(_ file_path: UnsafePointer<CChar>) -> UnsafePointer<CChar>?

@_silgen_name("c_zsign_get_metadata")
func c_zsign_get_metadata(_ app_folder: UnsafePointer<CChar>, _ output_dir: UnsafePointer<CChar>, _ ipa_file: UnsafePointer<CChar>) -> UnsafePointer<CChar>?
