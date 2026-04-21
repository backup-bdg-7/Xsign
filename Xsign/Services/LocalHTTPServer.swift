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
        let parameters = NWParameters.tcp
        // In a real robust implementation, we would add TLS here with a self-signed cert
        // to satisfy the 'secure' requirement and iOS itms-services requirements.

        listener = try NWListener(using: parameters, on: port)

        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Server ready on port \(self.port)")
            case .failed(let error):
                print("Server failed: \(error)")
            default:
                break
            }
        }

        listener?.newConnectionHandler = { connection in
            self.handleConnection(connection)
        }

        listener?.start(queue: .main)
    }

    func stop() {
        listener?.cancel()
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .main)
        receiveRequest(connection)
    }

    private func receiveRequest(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                let request = String(data: data, encoding: .utf8) ?? ""
                self.processRequest(request, connection: connection)
            }

            if error != nil || isComplete {
                connection.cancel()
            }
        }
    }

    private func processRequest(_ request: String, connection: NWConnection) {
        let lines = request.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else { return }
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else { return }

        let path = parts[1]

        if path == "/manifest.plist" {
            let manifestPath = FileManager.default.temporaryDirectory.appendingPathComponent("manifest.plist")
            serveFile(at: manifestPath, contentType: "text/xml", connection: connection)
        } else if path.hasPrefix("/download/") {
            let fileName = String(path.dropFirst(10))
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            serveFile(at: fileURL, contentType: "application/octet-stream", connection: connection)
        } else {
            sendResponse(status: "404 Not Found", body: "Not Found", connection: connection)
        }
    }

    private func serveFile(at url: URL, contentType: String, connection: NWConnection) {
        guard let data = try? Data(contentsOf: url) else {
            sendResponse(status: "404 Not Found", body: "File Not Found", connection: connection)
            return
        }

        let header = """
        HTTP/1.1 200 OK\r
        Content-Type: \(contentType)\r
        Content-Length: \(data.count)\r
        Connection: close\r
        \r
        """

        var responseData = header.data(using: .utf8)!
        responseData.append(data)

        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private func sendResponse(status: String, body: String, connection: NWConnection) {
        let response = "HTTP/1.1 \(status)\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\r\n\(body)"
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
