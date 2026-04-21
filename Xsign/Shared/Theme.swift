import SwiftUI

struct XsignTheme {
    static let primary = Color(hex: "7E22CE")    // Purple
    static let secondary = Color(hex: "4C1D95")  // Darker Purple
    static let background = Color(hex: "0F0F0F") // Black
    static let surface = Color(hex: "1A1A2E")    // Dark Navy/Surface
    static let textPrimary = Color(hex: "E8E8E8")
    static let textSecondary = Color(hex: "A0A0B0")
    static let success = Color(hex: "10B981")
    static let error = Color(hex: "EF4444")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
