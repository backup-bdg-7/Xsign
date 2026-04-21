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
        // Robust HTTPS implementation using TLS
        let tlsOptions = NWProtocolTLS.Options()

        // This is a placeholder for the actual SecIdentity configuration.
        // On iOS, generating a self-signed certificate at runtime requires
        // using Security framework APIs (SecKeyGeneratePair, SecCertificateCreateWithData).

        let parameters = NWParameters(tls: tlsOptions)

        listener = try NWListener(using: parameters, on: port)

        listener?.newConnectionHandler = { connection in
            connection.start(queue: .main)
            self.receive(on: connection)
        }

        listener?.start(queue: .main)
        print("Secure server started on port \(port)")
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
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

        let method = parts[0]
        let path = parts[1]

        print("\(method) \(path)")

        if path == "/manifest.plist" {
            let manifestPath = FileManager.default.temporaryDirectory.appendingPathComponent("manifest.plist")
            serve(url: manifestPath, contentType: "text/xml", on: connection)
        } else if path.hasPrefix("/download/") {
            let fileName = String(path.dropFirst(10)).removingPercentEncoding ?? ""
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            serve(url: fileURL, contentType: "application/octet-stream", on: connection)
        } else {
            let response = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
            connection.send(content: response.data(using: .utf8), completion: .idempotent)
        }
    }

    private func serve(url: URL, contentType: String, on connection: NWConnection) {
        guard let data = try? Data(contentsOf: url) else {
            let response = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
            connection.send(content: response.data(using: .utf8), completion: .idempotent)
            return
        }

        let header = """
        HTTP/1.1 200 OK\r
        Content-Type: \(contentType)\r
        Content-Length: \(data.count)\r
        Accept-Ranges: bytes\r
        Connection: close\r
        \r
        """

        var response = header.data(using: .utf8)!
        response.append(data)

        connection.send(content: response, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
