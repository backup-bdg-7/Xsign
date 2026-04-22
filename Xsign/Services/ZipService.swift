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
        try FileManager.default.zipItem(at: directory, to: destination)
    }
}
