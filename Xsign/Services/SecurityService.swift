import Foundation
import CryptoKit

class SecurityService {
    static let shared = SecurityService()

    private var symmetricKey: SymmetricKey?

    private init() {
        self.symmetricKey = loadOrGenerateKey()
    }

    private func loadOrGenerateKey() -> SymmetricKey {
        let keyPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent(".xsign_master_key")

        if let keyData = try? Data(contentsOf: keyPath) {
            return SymmetricKey(data: keyData)
        } else {
            let newKey = SymmetricKey(size: .bits256)
            newKey.withUnsafeBytes { bytes in
                let data = Data(bytes)
                // Use complete file protection for the master key
                try? data.write(to: keyPath, options: .completeFileProtection)
            }
            return newKey
        }
    }

    func encrypt(_ data: Data) throws -> Data {
        guard let key = symmetricKey else { throw NSError(domain: "Security", code: 1) }
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }

    func decrypt(_ data: Data) throws -> Data {
        guard let key = symmetricKey else { throw NSError(domain: "Security", code: 2) }
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}
