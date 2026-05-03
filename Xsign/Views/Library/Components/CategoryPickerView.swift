import SwiftUI
import SwiftData

struct CategoryPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query private var categories: [Category]
    let fileURL: URL
    @State private var newCategoryName = ""
    @State private var showingNewCategoryField = false
    
    var body: some View {
        List {
            Section("Create New") {
                if showingNewCategoryField {
                    HStack {
                        TextField("Category Name", text: $newCategoryName)
                        Button("Save") { createAndAssign() }
                            .disabled(newCategoryName.isEmpty)
                    }
                } else {
                    Button("New Category") { showingNewCategoryField = true }
                }
            }
            Section("Existing Categories") {
                ForEach(categories) { cat in
                    HStack {
                        Image(systemName: cat.icon)
                            .foregroundColor(colorFromString(cat.color))
                        Text(cat.name)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { assignToCategory(cat) }
                }
            }
            Section("Default") {
                Button("Misc (No Category)") { assignToDefault() }
            }
        }
    }
    
    func createAndAssign() {
        let cat = Category(name: newCategoryName, icon: "folder", color: "gray")
        modelContext.insert(cat)
        assignToCategory(cat)
    }
    
    func assignToCategory(_ cat: Category) {
        guard let fileName = fileURL.lastPathComponent.lowercased().removingPercentEncoding else { return }
        if fileName.hasSuffix(".ipa") || fileName.hasSuffix(".dylib") || fileName.hasSuffix(".deb") {
            Task {
                do {
                    let app = try await FileService.shared.importFile(at: fileURL)
                    app.category = cat
                    try modelContext.save()
                    dismiss()
                } catch {
                    print("Import failed: \(error)")
                    dismiss()
                }
            }
        } else { dismiss() }
    }
    
    func assignToDefault() {
        guard let fileName = fileURL.lastPathComponent.lowercased().removingPercentEncoding else { return }
        if fileName.hasSuffix(".ipa") || fileName.hasSuffix(".dylib") || fileName.hasSuffix(".deb") {
            Task {
                do {
                    _ = try await FileService.shared.importFile(at: fileURL)
                    dismiss()
                } catch {
                    print("Import failed: \(error)")
                    dismiss()
                }
            }
        } else { dismiss() }
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
