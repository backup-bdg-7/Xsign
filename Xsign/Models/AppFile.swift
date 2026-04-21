import Foundation
import SwiftData

@Model
final class AppFile: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var fileName: String
    var relativePath: String
    var type: FileType
    var size: Int64
    var creationDate: Date
    var bundleID: String?
    var version: String?
    var build: String?
    var isSigned: Bool
    var signatureStatus: SignatureStatus
    @Relationship(deleteRule: .cascade) var entitlements: [Entitlement]?
    var category: Category?
    var lastSignedDate: Date?

    var filePath: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(relativePath)
    }

    init(id: UUID = UUID(),
         name: String,
         fileName: String,
         relativePath: String,
         type: FileType,
         size: Int64,
         creationDate: Date = Date(),
         bundleID: String? = nil,
         version: String? = nil,
         build: String? = nil,
         isSigned: Bool = false,
         signatureStatus: SignatureStatus = .unsigned,
         entitlements: [Entitlement]? = nil,
         category: Category? = nil,
         lastSignedDate: Date? = nil) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.relativePath = relativePath
        self.type = type
        self.size = size
        self.creationDate = creationDate
        self.bundleID = bundleID
        self.version = version
        self.build = build
        self.isSigned = isSigned
        self.signatureStatus = signatureStatus
        self.entitlements = entitlements
        self.category = category
        self.lastSignedDate = lastSignedDate
    }
}
