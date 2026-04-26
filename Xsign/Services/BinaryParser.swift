import Foundation
import BitByteData

/**
 * BinaryParser performs deep analysis of Mach-O files.
 * It iterates through Load Commands to identify linked dylibs and architectures.
 */
class BinaryParser {
    static let shared = BinaryParser()
    private init() {}

    /// Extracts a list of linked dylibs from a Mach-O file (Universal or Thin).
    func getDylibs(at url: URL) -> [String] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return parseData(data)
    }

    private func parseData(_ data: Data) -> [String] {
        if data.count < 32 { return [] }
        let reader = LittleEndianByteReader(data: data)
        let magic = reader.readUInt32()

        // Handle Fat Binary (Universal) by iterating over architectures
        if magic == 0xCAFEBABE || magic == 0xBEBAFECA {
            let numArchs = reader.readUInt32().bigEndian
            var allDylibs: Set<String> = []
            for _ in 0..<Int(numArchs) {
                let _ = reader.readUInt32().bigEndian // cputype
                let _ = reader.readUInt32() // cpusubtype
                let offset = reader.readUInt32().bigEndian
                let size = reader.readUInt32().bigEndian
                let _ = reader.readUInt32().bigEndian // align

                let subData = data.subrange(in: Int(offset)..<Int(offset + size))
                allDylibs.formUnion(parseMachO(subData))
            }
            return Array(allDylibs)
        } else {
            return parseMachO(data)
        }
    }

    private func parseMachO(_ data: Data) -> [String] {
        if data.count < 32 { return [] }
        let reader = LittleEndianByteReader(data: data)
        let magic = reader.readUInt32()

        let is64 = magic == 0xFEEDFACF
        let is32 = magic == 0xFEEDFACE

        guard is64 || is32 else { return [] }

        // Skip header fields to get to command count (ncmds)
        let _ = reader.readUInt32() // cputype
        let _ = reader.readUInt32() // cpusubtype
        let _ = reader.readUInt32() // filetype
        let ncmds = reader.readUInt32()
        let _ = reader.readUInt32() // sizeofcmds
        let _ = reader.readUInt32() // flags
        if is64 { let _ = reader.readUInt32() } // reserved

        var dylibs: [String] = []

        // Iterate through all Load Commands
        for _ in 0..<Int(ncmds) {
            let cmdStart = reader.offset
            let cmd = reader.readUInt32()
            let cmdsize = reader.readUInt32()

            // Check for LC_LOAD_DYLIB or LC_LOAD_WEAK_DYLIB
            if cmd == 0xC || cmd == 0x80000018 {
                let offset = reader.readUInt32()
                let pathOffset = Int(cmdStart) + Int(offset)
                let pathData = data.subrange(in: pathOffset..<Int(cmdStart + UInt64(cmdsize)))
                if let path = String(data: pathData, encoding: .utf8)?.split(separator: "\0").first {
                    dylibs.append(String(path))
                }
            }
            reader.offset = cmdStart + UInt64(cmdsize)
        }
        return dylibs
    }
}
