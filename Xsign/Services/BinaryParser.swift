import Foundation
import BitByteData

class BinaryParser {
    static let shared = BinaryParser()
    private init() {}

    func getDylibs(at url: URL) -> [String] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        if data.count < 32 { return [] }

        let reader = LittleEndianByteReader(data: data)
        let magic = reader.readUInt32()

        // Mach-O arm64 magic number
        guard magic == 0xFEEDFACF else { return [] }

        let _ = reader.readUInt32() // cputype
        let _ = reader.readUInt32() // cpusubtype
        let _ = reader.readUInt32() // filetype
        let ncmds = reader.readUInt32()
        let _ = reader.readUInt32() // sizeofcmds
        let _ = reader.readUInt32() // flags
        let _ = reader.readUInt32() // reserved

        var dylibs: [String] = []

        for _ in 0..<Int(ncmds) {
            let cmd = reader.readUInt32()
            let cmdsize = reader.readUInt32()

            if cmd == 0xC || cmd == 0x80000018 { // LC_LOAD_DYLIB or LC_LOAD_WEAK_DYLIB
                let offset = reader.readUInt32()
                let _ = reader.readUInt32() // timestamp
                let _ = reader.readUInt32() // current_version
                let _ = reader.readUInt32() // compatibility_version

                // Extract dylib path from the load command
                let pathData = data.subrange(in: Int(reader.offset - 24 + offset)..<Int(reader.offset - 24 + cmdsize))
                if let path = String(data: pathData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) {
                    dylibs.append(path)
                }
            }

            reader.offset += UInt64(cmdsize - 8)
        }

        return dylibs
    }
}
