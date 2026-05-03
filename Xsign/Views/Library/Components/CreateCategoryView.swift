import SwiftUI
import SwiftData

struct CreateCategoryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @State private var name = ""
    @State private var selectedIcon = "folder"
    @State private var selectedColor = "blue"
    
    let icons = ["folder", "app", "doc", "archivebox", "bolt", "gearshape"]
    let colors = ["blue", "green", "orange", "purple", "pink", "red"]
    
    var body: some View {
        Form {
            Section("Category Details") { TextField("Name", text: $name) }
            Section("Icon") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                    ForEach(icons, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.title3)
                            .padding(8)
                            .background(selectedIcon == icon ? XsignTheme.primary.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                            .onTapGesture { selectedIcon = icon }
                    }
                }
            }
            Section("Color") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                    ForEach(colors, id: \.self) { color in
                        Circle()
                            .fill(colorFromString(color))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                            )
                            .onTapGesture { selectedColor = color }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    let cat = Category(name: name, icon: selectedIcon, color: selectedColor)
                    modelContext.insert(cat)
                    try? modelContext.save()
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
    
    func colorFromString(_ name: String) -> Color {
        switch name.lowercased() {
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
