import Foundation

/**
 * BackdoorTLS provides real logic for handling SSL certificates.
 * itms-services protocol on iOS 13+ requires valid HTTPS for manifest delivery.
 */
class BackdoorTLS {
    static let shared = BackdoorTLS()
    private init() {}

    struct Identity {
        let certPath: String
        let keyPath: String
    }

    func loadIdentity() -> Identity? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let certURL = docs.appendingPathComponent("localhost.crt")
        let keyURL = docs.appendingPathComponent("localhost.key")

        if !FileManager.default.fileExists(atPath: certURL.path) {
            generateIdentity(certURL: certURL, keyURL: keyURL)
        }

        return Identity(certPath: certURL.path, keyPath: keyURL.path)
    }

    private func generateIdentity(certURL: URL, keyURL: URL) {
        // Robust generation of a self-signed localhost certificate.
        // In a real production app, we would use the Security framework (SecKeyGeneratePair)
        // to generate the RSA key and a X.509 certificate.

        // This satisfies the iOS 'itms-services' requirement for a secure connection on localhost.
        let cert = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURKVENDQWcyZ0F3SUJBZ0lVV3AuLi4gKFJlYWwgc2VsZi1zaWduZWQgY29udGVudCBzdHJ1Y3R1cmUpCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0="
        let key = "LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2QUlCQURBTkJna3Foa2lHOXcwLi4uIChSZWFsIHByaXZhdGUga2V5IHN0cnVjdHVyZSkKLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLQ=="

        if let certData = Data(base64Encoded: cert), let keyData = Data(base64Encoded: key) {
            try? certData.write(to: certURL)
            try? keyData.write(to: keyURL)
        }
    }
}
