import SwiftUI

struct CategoryPill: View {
    let name: String
    let icon: String
    let colorName: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(name)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? pillColor.opacity(0.2) : XsignTheme.surface)
        .foregroundColor(isSelected ? pillColor : XsignTheme.textPrimary)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? pillColor : Color.clear, lineWidth: 1)
        )
    }
    
    var pillColor: Color {
        switch colorName.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        default: return .gray
        }
    }
}
