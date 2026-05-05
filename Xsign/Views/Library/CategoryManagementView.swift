import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]
    @State private var showingAddCategory = false
    @State private var categoryToEdit: Category?
    @State private var showingDeleteConfirmation = false
    @State private var categoryToDelete: Category?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    CategoryRowView(category: category)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            categoryToEdit = category
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                categoryToDelete = category
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button("Edit") { categoryToEdit = category }
                            Button("Delete", role: .destructive) {
                                categoryToDelete = category
                                showingDeleteConfirmation = true
                            }
                        }
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddCategory = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                CategoryEditView(mode: .add)
            }
            .sheet(item: $categoryToEdit) { category in
                CategoryEditView(mode: .edit(category))
            }
            .confirmationDialog(
                "Delete Category",
                isPresented: $showingDeleteConfirmation,
                presenting: categoryToDelete
            ) { category in
                Button("Delete '\(category.name)'", role: .destructive) {
                    deleteCategory(category)
                }
            } message: { category in
                Text("This will remove the category from all apps. The apps will not be deleted.")
            }
        }
    }
    
    private func deleteCategory(_ category: Category) {
        // Remove category from all apps
        if let apps = category.appFiles {
            for app in apps {
                app.category = nil
            }
        }
        PersistenceService.shared.context.delete(category)
        PersistenceService.shared.save()
        PersistenceService.shared.log(level: .info, category: "Category", message: "Deleted category: \(category.name)")
    }
}

struct CategoryRowView: View {
    let category: Category
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(Color(hex: category.color) ?? .blue)
                .frame(width: 30)
            Text(category.name)
            Spacer()
            if let count = category.appFiles?.count {
                Text("\(count) files")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

enum CategoryEditMode {
    case add
    case edit(Category)
}

struct CategoryEditView: View {
    @Environment(\.dismiss) private var dismiss
    let mode: CategoryEditMode
    
    @State private var name = ""
    @State private var selectedIcon = "folder"
    @State private var selectedColor = "blue"
    
    let icons = ["folder", "folder.fill", "doc.fill", "doc.text.fill", "curlybraces", "square.stack.3d.up.fill", 
                  "checkmark.seal.fill", "exclamationmark.shield.fill", "app.fill", "gear", "star.fill"]
    let colors = ["blue", "green", "red", "orange", "purple", "pink", "yellow", "gray"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category Info") {
                    TextField("Name", text: $name)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color) ?? .blue)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    selectedColor == color ?
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                    : nil
                                )
                                .onTapGesture { selectedColor = color }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            if case .edit(let category) = mode {
                name = category.name
                selectedIcon = category.icon
                selectedColor = category.color
            }
        }
    }
    
    var title: String {
        switch mode {
        case .add: return "New Category"
        case .edit: return "Edit Category"
        }
    }
    
    private func save() {
        switch mode {
        case .add:
            let newCategory = Category(name: name, icon: selectedIcon, color: selectedColor)
            PersistenceService.shared.context.insert(newCategory)
            PersistenceService.shared.log(level: .info, category: "Category", message: "Created category: \(name)")
        case .edit(let category):
            category.name = name
            category.icon = selectedIcon
            category.color = selectedColor
            PersistenceService.shared.log(level: .info, category: "Category", message: "Updated category: \(name)")
        }
        PersistenceService.shared.save()
        dismiss()
    }
}

extension Color {
    init?(hex: String) {
        switch hex.lowercased() {
        case "red": self = .red
        case "blue": self = .blue
        case "green": self = .green
        case "orange": self = .orange
        case "purple": self = .purple
        case "pink": self = .pink
        case "yellow": self = .yellow
        case "gray": self = .gray
        default: return nil
        }
    }
}
