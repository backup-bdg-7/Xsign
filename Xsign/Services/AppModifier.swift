import Foundation

class AppModifier {
    static let shared = AppModifier()
    private init() {}

    func modifyApp(at ipaURL: URL, newBundleID: String?, newVersion: String?, newBuild: String?) throws -> URL {
        let workingDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workingDir, withIntermediateDirectories: true)

        // 1. Unzip
        try ZipService.shared.unzip(at: ipaURL, to: workingDir)

        // 2. Modify Info.plist
        let payloadDir = workingDir.appendingPathComponent("Payload")
        let contents = try FileManager.default.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil)
        guard let appDir = contents.first(where: { $0.pathExtension == "app" }) else {
            throw NSError(domain: "AppModifier", code: 1, userInfo: [NSLocalizedDescriptionKey: "App bundle not found"])
        }

        let plistURL = appDir.appendingPathComponent("Info.plist")
        if var plist = try? PropertyListSerialization.propertyList(from: Data(contentsOf: plistURL), options: [], format: nil) as? [String: Any] {
            if let bundleID = newBundleID { plist["CFBundleIdentifier"] = bundleID }
            if let version = newVersion { plist["CFBundleShortVersionString"] = version }
            if let build = newBuild { plist["CFBundleVersion"] = build }

            let updatedData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try updatedData.write(to: plistURL)
        }

        // 3. Re-zip
        let outputIPA = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).ipa")
        try ZipService.shared.zip(directory: workingDir, to: outputIPA)

        return outputIPA
    }
}
