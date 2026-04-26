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
        let magic = reader.uint32()

        // Handle Fat Binary (Universal) by iterating over architectures
        if magic == 0xCAFEBABE || magic == 0xBEBAFECA {
            let numArchs = Int(reader.uint32().bigEndian)
            var allDylibs: Set<String> = []
            for _ in 0..<numArchs {
                let _ = reader.uint32().bigEndian // cputype
                let _ = reader.uint32() // cpusubtype
                let offset = UInt64(reader.uint32().bigEndian)
                let size = UInt64(reader.uint32().bigEndian)
                let _ = reader.uint32() // align

                let subData = data.subdata(in: Int(offset)..<Int(offset + size))
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
        let magic = reader.uint32()

        let is64 = magic == 0xFEEDFACF
        let is32 = magic == 0xFEEDFACE

        guard is64 || is32 else { return [] }

        // Skip header fields to get to command count (ncmds)
        let _ = reader.uint32() // cputype
        let _ = reader.uint32() // cpusubtype
        let _ = reader.uint32() // filetype
        let ncmds = reader.uint32()
        let _ = reader.uint32() // sizeofcmds
        let _ = reader.uint32() // flags
        if is64 { let _ = reader.uint32() } // reserved

        var dylibs: [String] = []

        // Iterate through all Load Commands
        for _ in 0..<Int(ncmds) {
            let cmdStart = reader.offset
            let cmd = reader.uint32()
            let cmdsize = reader.uint32()

            // Check for LC_LOAD_DYLIB or LC_LOAD_WEAK_DYLIB
            if cmd == 0xC || cmd == 0x80000018 {
                let offset = reader.uint32()
                let pathOffset = Int(cmdStart) + Int(offset)
                let endOffset = Int(cmdStart) + Int(cmdsize)
                let pathData = data.subdata(in: pathOffset..<endOffset)
                if let path = String(data: pathData, encoding: .utf8)?.split(separator: "\0").first {
                    dylibs.append(String(path))
                }
            }
            reader.offset = cmdStart + Int(cmdsize)
        }
        return dylibs
    }
}
