import Foundation
import Security
import Vapor
import NIOSSL

/**
 * BackdoorTLS provides TLS certificate handling for the itms-services protocol.
 * iOS 13+ requires valid HTTPS for manifest delivery.
 * Based on Feather's ServerInstaller+TLS.swift implementation.
 */
class BackdoorTLS {
    static let shared = BackdoorTLS()
    private init() {}

    struct Identity {
        let certPath: String
        let keyPath: String
    }

    /// Load or generate TLS identity for local server
    func loadIdentity() -> Identity? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let certURL = docs.appendingPathComponent("server.crt")
        let keyURL = docs.appendingPathComponent("server.key")

        // Check if certificates exist in documents
        if !FileManager.default.fileExists(atPath: certURL.path) {
            // Try to copy from bundle first
            if let bundleCert = Bundle.main.url(forResource: "server", withExtension: "crt"),
               let bundleKey = Bundle.main.url(forResource: "server", withExtension: "key") {
                try? FileManager.default.copyItem(at: bundleCert, to: certURL)
                try? FileManager.default.copyItem(at: bundleKey, to: keyURL)
            } else {
                // Generate self-signed certificate
                generateIdentity(certURL: certURL, keyURL: keyURL)
            }
        }

        // Also check for commonName file (like Feather does)
        let commonNameURL = docs.appendingPathComponent("commonName.txt")
        if !FileManager.default.fileExists(atPath: commonNameURL.path) {
            // Write the common name (localhost or local IP)
            let commonName = getCommonName()
            try? commonName.write(to: commonNameURL, atomically: true, encoding: .utf8)
        }

        return Identity(certPath: certURL.path, keyPath: keyURL.path)
    }

    /// Get the common name for the certificate (like Feather's readCommonName)
    private func getCommonName() -> String {
        if let name = readCommonName() {
            return name
        }

        // Default to localhost
        return "127.0.0.1"
    }

    /// Read common name from file (like Feather)
    func readCommonName() -> String? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("commonName.txt")

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        return try? String(contentsOf: url, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Generate self-signed certificate and key
    private func generateIdentity(certURL: URL, keyURL: URL) {
        // Use OpenSSL via command line to generate self-signed cert
        // This is a fallback - ideally certificates should be pre-bundled like Feather

        let script = """
        openssl req -x509 -newkey rsa:2048 -keyout "\(keyURL.path)" -out "\(certURL.path)" \
        -days 365 -nodes -subj "/CN=127.0.0.1" 2>/dev/null
        """

        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", script]
        try? task.run()
        task.waitUntilExit()
    }

    /// Get TLS configuration for Vapor (like Feather's tls() function)
    func makeTLSConfiguration() throws -> TLSConfiguration? {
        guard let identity = loadIdentity() else {
            return nil
        }

        guard
            FileManager.default.fileExists(atPath: identity.certPath),
            FileManager.default.fileExists(atPath: identity.keyPath)
        else {
            return nil
        }

        return try TLSConfiguration.makeServerConfiguration(
            certificateChain: NIOSSLCertificate.fromPEMFile(identity.certPath).map {
                NIOSSLCertificateSource.certificate($0)
            },
            privateKey: .privateKey(
                try NIOSSLPrivateKey(file: identity.keyPath, format: .pem)
            )
        )
    }

    /// Get the server hostname for SNI (like Feather's sni() function)
    func sni() -> String {
        let localhost = "127.0.0.1"

        // Check if we should use IP or common name
        if getServerMethod() != 1 {
            return readCommonName() ?? localhost
        } else {
            // Use local address or localhost
            return getLocalAddress() ?? localhost
        }
    }

    private func getServerMethod() -> Int {
        // 0 = Auto, 1 = Localhost, 2 = Network IP
        return UserDefaults.standard.integer(forKey: "serverMethod")
    }

    /// Get local network IP address
    private func getLocalAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let interface = ptr!.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family

                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" || name == "pdp_ip0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                       &hostname, socklen_t(hostname.count),
                                       nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                            address = String(cString: hostname)
                        }
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }

        return address
    }
}
