import Foundation
import BitByteData

class BinaryParser {
    static let shared = BinaryParser()
    private init() {}

    func parseMachO(at url: URL) -> MachOInfo? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        if data.count < 32 { return nil }

        let reader = LittleEndianByteReader(data: data)
        let magic = reader.readUInt32()

        var architectures: [String] = []

        if magic == 0xCAFEBABE || magic == 0xBEBAFECA { // Fat
            let numArchs = reader.readUInt32().bigEndian
            for _ in 0..<Int(numArchs) {
                let cputype = reader.readUInt32().bigEndian
                let _ = reader.readUInt32() // cpusubtype
                let _ = reader.readUInt32().bigEndian // offset
                let _ = reader.readUInt32().bigEndian // size
                let _ = reader.readUInt32().bigEndian // align

                if cputype == 16777228 { architectures.append("arm64") }
                else if cputype == 12 { architectures.append("armv7") }
            }
        } else if magic == 0xFEEDFACF { // 64-bit
            architectures.append("arm64")
        }

        return MachOInfo(architectures: architectures, linkedLibraries: [], platform: "iOS", minOS: "15.0")
    }
}
