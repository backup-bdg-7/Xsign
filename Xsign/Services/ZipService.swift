import Foundation
import ZIPFoundation

class ZipService {
    static let shared = ZipService()
    private init() {}

    func unzip(at source: URL, to destination: URL) throws {
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try FileManager.default.unzipItem(at: source, to: destination)
    }

    func zip(directory: URL, to destination: URL) throws {
        let fileManager = FileManager.default
        let archive = try Archive(url: destination, accessMode: .create)

        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        for item in contents {
            try archive.addEntry(with: item.lastPathComponent, relativeTo: directory)
        }
    }
}
