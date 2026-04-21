import Foundation
import CryptoKit

class SecurityService {
    static let shared = SecurityService()

    // A stable key for the app sandbox (in a real app, this might be derived from a device-specific secret)
    private let symmetricKey: SymmetricKey

    private init() {
        // For demonstration purposes, we use a static key.
        // In a real app, you would store this in a secure file within the sandbox,
        // ideally protected by the Secure Enclave or a user-provided passphrase.
        let keyData = "xsign-local-secret-key-32-bytes!!".data(using: .utf8)!
        self.symmetricKey = SymmetricKey(data: keyData)
    }

    func encrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        return sealedBox.combined!
    }

    func decrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
}
