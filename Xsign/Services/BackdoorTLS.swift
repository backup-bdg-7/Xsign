import Foundation

/**
 * BackdoorTLS provides real logic for handling SSL certificates for the local installation server.
 * This ensures 'itms-services' installation URLs are trusted by iOS.
 */
class BackdoorTLS {
    static let shared = BackdoorTLS()
    private init() {}

    struct Identity {
        let certPath: String
        let keyPath: String
    }

    /**
     * Loads the TLS identity. In a production app, this would involve
     * a network call to backdoor.dev to obtain a signed certificate for localhost.
     */
    func loadIdentity() -> Identity? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let certURL = docs.appendingPathComponent("localhost.crt")
        let keyURL = docs.appendingPathComponent("localhost.key")

        // Ensure certificates exist
        guard FileManager.default.fileExists(atPath: certURL.path),
              FileManager.default.fileExists(atPath: keyURL.path) else {
            return nil
        }

        return Identity(certPath: certURL.path, keyPath: keyURL.path)
    }
}
