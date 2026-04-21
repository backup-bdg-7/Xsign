import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var showingAddCategory = false
    @State private var newCategoryName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()

                if categories.isEmpty {
                    ContentUnavailableView("No Categories", systemImage: "square.grid.2x2", description: Text("Create categories to organize your apps."))
                        .foregroundColor(XsignTheme.textSecondary)
                } else {
                    List {
                        ForEach(categories) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(Color(hex: category.color))
                                    .frame(width: 30)

                                Text(category.name)
                                    .foregroundColor(XsignTheme.textPrimary)

                                Spacer()

                                Text("\(category.appFiles.count) apps")
                                    .font(.caption)
                                    .foregroundColor(XsignTheme.textSecondary)
                            }
                            .listRowBackground(XsignTheme.surface)
                        }
                        .onDelete(perform: deleteCategories)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCategory = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
        }
    }

    private func deleteCategories(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
        try? modelContext.save()
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var name = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = "7E22CE"

    let icons = ["folder.fill", "tag.fill", "star.fill", "gamecontroller.fill", "hammer.fill", "wrench.and.screwdriver.fill"]
    let colors = ["7E22CE", "10B981", "EF4444", "3B82F6", "F59E0B", "6366F1"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Category Info") {
                    TextField("Name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
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
                                .fill(Color(hex: color))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                )
                                .onTapGesture { selectedColor = color }
                        }
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newCategory = Category(name: name, icon: selectedIcon, color: selectedColor)
                        modelContext.insert(newCategory)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
