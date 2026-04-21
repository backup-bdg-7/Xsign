import Foundation
import Network

class LocalHTTPServer {
    private var listener: NWListener?
    private let port: NWEndpoint.Port
    private let documentsDirectory: URL

    init(port: UInt16 = 8443) {
        self.port = NWEndpoint.Port(integerLiteral: port)
        self.documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func start() throws {
        // iOS itms-services installation requires HTTPS.
        // We use NWParameters with TLS.
        let tlsOptions = NWProtocolTLS.Options()
        // In a real robust app, we'd configure a self-signed identity here
        // sec_protocol_options_set_local_identity(...)

        let parameters = NWParameters(tls: tlsOptions)

        listener = try NWListener(using: parameters, on: port)

        listener?.newConnectionHandler = { connection in
            connection.start(queue: .main)
            self.receive(on: connection)
        }

        listener?.start(queue: .main)
    }

    func stop() {
        listener?.cancel()
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, isComplete, error in
            if let data = data, let request = String(data: data, encoding: .utf8) {
                self.handle(request: request, on: connection)
            }
            if error != nil || isComplete { connection.cancel() }
        }
    }

    private func handle(request: String, on connection: NWConnection) {
        let lines = request.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else { return }
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else { return }

        let path = parts[1]

        if path == "/manifest.plist" {
            let manifestPath = FileManager.default.temporaryDirectory.appendingPathComponent("manifest.plist")
            serve(url: manifestPath, contentType: "text/xml", on: connection)
        } else if path.hasPrefix("/download/") {
            let fileName = String(path.dropFirst(10))
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            serve(url: fileURL, contentType: "application/octet-stream", on: connection)
        }
    }

    private func serve(url: URL, contentType: String, on connection: NWConnection) {
        guard let data = try? Data(contentsOf: url) else { return }
        let header = "HTTP/1.1 200 OK\r\nContent-Type: \(contentType)\r\nContent-Length: \(data.count)\r\nConnection: close\r\n\r\n"
        var response = header.data(using: .utf8)!
        response.append(data)
        connection.send(content: response, completion: .contentProcessed { _ in connection.cancel() })
    }
}
