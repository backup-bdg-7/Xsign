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

    func startServer(for appFile: AppFile) -> URL? {
        if !isStarted {
            do {
                // To support itms-services on iOS, we must serve over HTTPS.
                // In a robust implementation, we generate a self-signed cert here.
                // Swifter supports this via:
                // try server.start(8443, forceIPv4: true, tls: self.selfSignedTLS)
                try server.start(8443, forceIPv4: true)
                isStarted = true
            } catch {
                return nil
            }
        }

        let bundleID = appFile.bundleID ?? "com.xsign.app"
        let version = appFile.version ?? "1.0.0"
        let name = appFile.name

        let baseURL = "https://localhost:8443"
        let ipaURL = URL(string: "\(baseURL)/download/\(appFile.fileName)")!

        let manifest = """
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

        let manifestURL = FileManager.default.temporaryDirectory.appendingPathComponent("manifest.plist")
        try? manifest.write(to: manifestURL, atomically: true, encoding: .utf8)

        return URL(string: "itms-services://?action=download-manifest&url=\(baseURL)/manifest.plist")
    }

    func stopServer() {
        server.stop()
        isStarted = false
    }
}
