import Foundation
import Compression

class ZipService {
    static let shared = ZipService()
    private init() {}

    func unzip(at source: URL, to destination: URL) throws {
        // Use /usr/bin/unzip on iOS/macOS for speed and reliability in sandbox
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", source.path, "-d", destination.path]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw NSError(domain: "ZipService", code: Int(process.terminationStatus))
        }
    }

    func zip(directory: URL, to destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = directory
        process.arguments = ["-r", "-q", destination.path, "."]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw NSError(domain: "ZipService", code: Int(process.terminationStatus))
        }
    }
}
