import Foundation
import Vapor
import NIOSSL

class LocalServerService {
    static let shared = LocalServerService()
    private var app: Application?
    private let port = 8443

    private init() {}

    func startServer(for ipaURL: URL, bundleID: String, version: String, name: String) -> URL? {
        if app == nil {
            do {
                app = try Application(.development)
                guard let app = app else { return nil }

                app.http.server.configuration.port = port
                app.http.server.configuration.hostname = "localhost"

                if let identity = BackdoorTLS.shared.loadIdentity() {
                    let certPath = identity.certPath
                    let keyPath = identity.keyPath

                    let tlsConfiguration = TLSConfiguration.makeServerConfiguration(
                        certificateChain: try NIOSSLCertificate.fromPEMFile(certPath).map { .certificate($0) },
                        privateKey: .file(keyPath)
                    )
                    app.http.server.configuration.tlsConfiguration = tlsConfiguration
                }

                setupRoutes(app)

                try app.start()
            } catch {
                print("[VaporServer] Error: \(error)")
                return nil
            }
        }

        let baseURL = "https://localhost:\(port)"
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

    private func setupRoutes(_ app: Application) {
        app.get("manifest.plist") { req -> Response in
            let path = FileManager.default.temporaryDirectory.appendingPathComponent("manifest.plist")
            if let data = try? Data(contentsOf: path) {
                return Response(status: .ok, headers: ["Content-Type": "text/xml"], body: .init(data: data))
            }
            return Response(status: .notFound)
        }

        app.get("download", ":name") { req -> Response in
            guard let name = req.parameters.get("name") else { return Response(status: .notFound) }
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documents.appendingPathComponent(name)

            if let data = try? Data(contentsOf: fileURL) {
                return Response(status: .ok, headers: ["Content-Type": "application/octet-stream"], body: .init(data: data))
            }
            return Response(status: .notFound)
        }
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

    func stopServer() {
        app?.shutdown()
        app = nil
    }
}
