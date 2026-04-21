import Foundation
import SwiftData

enum CertificateType: String, Codable {
    case development, distribution, enterprise
}

@Model
final class Certificate: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String

    // Encrypted storage
    var encryptedP12Data: Data
    var provisioningProfileData: Data?
    var encryptedPassword: Data?

    var type: CertificateType
    var expiryDate: Date
    var commonName: String
    var fingerprint: String
    var canSign: Bool

    init(id: UUID = UUID(),
         name: String,
         p12Data: Data,
         provisioningProfileData: Data? = nil,
         password: String? = nil,
         type: CertificateType,
         expiryDate: Date,
         commonName: String,
         fingerprint: String,
         canSign: Bool) {
        self.id = id
        self.name = name

        // Encrypt on initialization
        self.encryptedP12Data = (try? SecurityService.shared.encrypt(p12Data)) ?? p12Data
        self.provisioningProfileData = provisioningProfileData
        if let password = password, let passwordData = password.data(using: .utf8) {
            self.encryptedPassword = try? SecurityService.shared.encrypt(passwordData)
        }

        self.type = type
        self.expiryDate = expiryDate
        self.commonName = commonName
        self.fingerprint = fingerprint
        self.canSign = canSign
    }

    func decryptedPassword() -> String? {
        guard let encrypted = encryptedPassword,
              let decrypted = try? SecurityService.shared.decrypt(encrypted) else { return nil }
        return String(data: decrypted, encoding: .utf8)
    }

    func decryptedP12Data() throws -> Data {
        return try SecurityService.shared.decrypt(encryptedP12Data)
    }
}
