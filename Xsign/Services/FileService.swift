import Foundation

class FileService {
    static let shared = FileService()
    private init() {}

    func importFile(at url: URL) async throws -> AppFile {
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "FileService", code: 1)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let fileName = url.lastPathComponent
        let type: FileType
        if fileName.hasSuffix(".ipa") { type = .ipa }
        else if fileName.hasSuffix(".dylib") { type = .dylib }
        else if fileName.hasSuffix(".deb") { type = .deb }
        else { type = .zip }

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: url, to: destinationURL)

        var bundleID: String?
        var version: String?
        var build: String?
        var entitlements: [Entitlement] = []

        if type == .ipa {
            // Logic to find Info.plist and entitlements
            if let ipaEntitlements = EntitlementManager.shared.extractFromIPA(at: destinationURL) {
                for (key, _) in ipaEntitlements {
                    entitlements.append(Entitlement(
                        name: key,
                        entitlementDescription: "Extracted entitlement",
                        capabilityType: .other,
                        platform: "iOS",
                        isRequired: false
                    ))
                }
            }
        }

        let appFile = AppFile(
            name: fileName,
            fileName: fileName,
            relativePath: fileName,
            type: type,
            size: (try? destinationURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) } ?? 0,
            bundleID: bundleID,
            version: version,
            build: build,
            entitlements: entitlements.isEmpty ? nil : entitlements
        )

        await PersistenceService.shared.context.insert(appFile)
        await PersistenceService.shared.save()

        return appFile
    }
}
