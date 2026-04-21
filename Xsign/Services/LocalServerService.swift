import Foundation

class LocalServerService {
    static let shared = LocalServerService()
    private var server: LocalHTTPServer?

    private init() {}

    func generateManifest(bundleID: String, version: String, name: String, ipaURL: URL) -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>items</key>
            <array>
                <dict>
                    <key>assets</key>
                    <array>
                        <dict>
                            <key>kind</key>
                            <string>software-package</string>
                            <key>url</key>
                            <string>\(ipaURL.absoluteString)</string>
                        </dict>
                    </array>
                    <key>metadata</key>
                    <dict>
                        <key>bundle-identifier</key>
                        <string>\(bundleID)</string>
                        <key>bundle-version</key>
                        <string>\(version)</string>
                        <key>kind</key>
                        <string>software</string>
                        <key>title</key>
                        <string>\(name)</string>
                    </dict>
                </dict>
            </array>
        </dict>
        </plist>
        """
    }

    func startServer(for appFile: AppFile) -> URL? {
        let port: UInt16 = 8443
        if server == nil {
            server = LocalHTTPServer(port: port)
            try? server?.start()
        }

        let bundleID = appFile.bundleID ?? "com.xsign.app"
        let version = appFile.version ?? "1.0.0"
        let name = appFile.name

        let baseURL = "http://localhost:\(port)" // Should be https but for local simulation http is used
        let ipaDownloadURL = URL(string: "\(baseURL)/download/\(appFile.fileName)")!

        let manifestContent = generateManifest(bundleID: bundleID, version: version, name: name, ipaURL: ipaDownloadURL)
        let manifestURL = FileManager.default.temporaryDirectory.appendingPathComponent("manifest.plist")
        try? manifestContent.write(to: manifestURL, atomically: true, encoding: .utf8)

        let installURLString = "itms-services://?action=download-manifest&url=\(baseURL)/manifest.plist"
        return URL(string: installURLString)
    }

    func stopServer() {
        server?.stop()
        server = nil
    }
}
