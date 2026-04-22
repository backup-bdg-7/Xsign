import Foundation
import Swifter

class LocalServerService {
    static let shared = LocalServerService()
    private let server = HttpServer()
    private var isStarted = false

    private init() {
        setupRoutes()
    }

    private func setupRoutes() {
        server["/manifest.plist"] = { _ in
            let path = FileManager.default.temporaryDirectory.appendingPathComponent("manifest.plist")
            if let data = try? Data(contentsOf: path) {
                return .ok(.data(data, contentType: "text/xml"))
            }
            return .notFound
        }

        server["/download/:name"] = { request in
            guard let name = request.params[":name"] else { return .notFound }
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documents.appendingPathComponent(name)

            if let data = try? Data(contentsOf: fileURL) {
                return .ok(.data(data, contentType: "application/octet-stream"))
            }
            return .notFound
        }
    }

    func startServer(for ipaURL: URL, bundleID: String, version: String, name: String) -> URL? {
        if !isStarted {
            do {
                // itms-services requires HTTPS with a valid certificate.
                if let identity = BackdoorTLS.shared.loadIdentity() {
                    // try server.start(8443, forceIPv4: true, tls: (identity.certPath, identity.keyPath))
                }
                try server.start(8443, forceIPv4: true)
                isStarted = true
            } catch {
                return nil
            }
        }

        let baseURL = "https://localhost:8443"
        let downloadURL = URL(string: "\(baseURL)/download/\(ipaURL.lastPathComponent)")!

        let manifest = generateManifest(bundleID: bundleID, version: version, name: name, ipaURL: downloadURL)
        let manifestURL = FileManager.default.temporaryDirectory.appendingPathComponent("manifest.plist")
        try? manifest.write(to: manifestURL, atomically: true, encoding: .utf8)

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let serverFile = documents.appendingPathComponent(ipaURL.lastPathComponent)
        if !FileManager.default.fileExists(atPath: serverFile.path) {
            try? FileManager.default.copyItem(at: ipaURL, to: serverFile)
        }

        return URL(string: "itms-services://?action=download-manifest&url=\(baseURL)/manifest.plist")
    }

    private func generateManifest(bundleID: String, version: String, name: String, ipaURL: URL) -> String {
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
}
