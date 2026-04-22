import Foundation

class DylibInjector {
    static let shared = DylibInjector()
    private init() {}

    /// Injects a LC_LOAD_DYLIB command into a Mach-O binary.
    func inject(dylibPath: String, into executablePath: URL) throws {
        var data = try Data(contentsOf: executablePath)

        // 1. Validate Mach-O header
        let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        guard magic == 0xFEEDFACF else { return } // Only supporting arm64

        // 2. Locate load commands
        let ncmdsOffset = 16
        let sizeofcmdsOffset = 20
        var ncmds = data.withUnsafeBytes { $0.load(fromByteOffset: ncmdsOffset, as: UInt32.self) }
        var sizeofcmds = data.withUnsafeBytes { $0.load(fromByteOffset: sizeofcmdsOffset, as: UInt32.self) }

        // 3. Prepare new load command (dylib_command)
        let cmdSize = (UInt32(MemoryLayout<UInt32>.size * 6) + UInt32(dylibPath.count) + 1 + 7) & ~7

        // 4. Update Header
        ncmds += 1
        sizeofcmds += cmdSize

        withUnsafeMutableBytes(of: &ncmds) { data.replaceSubrange(ncmdsOffset..<ncmdsOffset+4, with: $0) }
        withUnsafeMutableBytes(of: &sizeofcmds) { data.replaceSubrange(sizeofcmdsOffset..<sizeofcmdsOffset+4, with: $0) }

        // 5. Append command data
        // LC_LOAD_DYLIB = 0xC
        var command: [UInt32] = [0xC, cmdSize, 24, 0, 0, 0]
        data.append(contentsOf: command.flatMap { withUnsafeBytes(of: $0) { Array($0) } })
        data.append(dylibPath.data(using: .utf8)!)
        data.append(0) // Null terminator

        // Padding
        let padding = Int(cmdSize) - (24 + dylibPath.count + 1)
        if padding > 0 { data.append(contentsOf: Array(repeating: 0, count: padding)) }

        try data.write(to: executablePath)
        print("Injected \(dylibPath) into Mach-O")
    }
}
