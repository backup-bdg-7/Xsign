import Foundation
import Zip

class ZipService {
    static let shared = ZipService()
    private init() {}

    func unzip(at source: URL, to destination: URL) throws {
        try Zip.unzipFile(source, destination: destination, overwrite: true, password: nil)
    }

    func zip(directory: URL, to destination: URL) throws {
        let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        try Zip.zipFiles(paths: contents, zipFilePath: destination, password: nil, progress: nil)
    }
}
