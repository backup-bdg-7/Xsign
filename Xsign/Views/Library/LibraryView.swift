import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \AppFile.creationDate, order: .reverse) private var appFiles: [AppFile]
    @Query private var categories: [Category]
    @State private var showingImportPicker = false
    @State private var showingCategoryCreator = false
    @State private var selectedCategoryID: UUID?
    @State private var importedFileURL: URL?
    @State private var showingCategoryPicker = false
    
    // Filter files by selected category
    var filteredFiles: [AppFile] {
        guard let categoryID = selectedCategoryID else { return Array(appFiles) }
        return appFiles.filter { $0.category?.id == categoryID }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()
                VStack {
                    // Category filter
                    if !categories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // "All" button
                                CategoryPill(name: "All", icon: "square.grid.2x2", color: "gray", isSelected: selectedCategoryID == nil)
                                    .onTapGesture { selectedCategoryID = nil }
                                
                                ForEach(categories) { category in
                                    CategoryPill(name: category.name, icon: category.icon, color: category.color, isSelected: selectedCategoryID == category.id)
                                        .onTapGesture { selectedCategoryID = category.id }
                                }
                            }.padding(.horizontal)
                        }.padding(.vertical, 8)
                    }
                    
                    if filteredFiles.isEmpty {
                        VStack(spacing: 16) {
                            LottieView(name: "empty", loopMode: .loop)
                                .frame(width: 200, height: 200)
                            Text("No Files")
                                .font(.headline)
                                .foregroundColor(XsignTheme.textSecondary)
                            Text("Import .ipa, .dylib, or .deb files")
                                .font(.caption)
                                .foregroundColor(XsignTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(filteredFiles) { file in
                                    NavigationLink(destination: AppDetailView(appFile: file)) { AppFileCard(appFile: file) }
                                }
                            }.padding()
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar { 
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: { showingCategoryCreator = true }) { 
                        Image(systemName: "folder.badge.plus")
                    }
                    Button(action: { showingImportPicker = true }) { 
                        Image(systemName: "plus") 
                    } 
                }
            }
            .sheet(isPresented: $showingCategoryCreator) {
                NavigationStack {
                    CreateCategoryView()
                        .navigationTitle("New Category")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showingCategoryCreator = false }
                            }
                        }
                }
            }
            .fileImporter(isPresented: $showingImportPicker, allowedContentTypes: [.ipa, .dylib, .deb]) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $showingCategoryPicker) {
                if let url = importedFileURL {
                    NavigationStack {
                        CategoryPickerView(fileURL: url)
                            .navigationTitle("Select Category")
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") { showingCategoryPicker = false }
                                }
                            }
                    }
                }
            }
        }
    }
    
    private func handleFileImport(_ result: Result<URL, Error>) {
        if let url = try? result.get() {
            importedFileURL = url
            showingCategoryPicker = true
        }
    }
}

struct CategoryPill: View {
    let name: String
    let icon: String
    let color: String
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
        .background(isSelected ? Color(color).opacity(0.2) : XsignTheme.surface)
        .foregroundColor(isSelected ? Color(color) : XsignTheme.textPrimary)
        .cornerRadius(20)
    }
}

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
            Section("Category Details") {
                TextField("Name", text: $name)
            }
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
                            .fill(Color(color))
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
                    let category = Category(name: name, icon: selectedIcon, color: selectedColor)
                    modelContext.insert(category)
                    try? modelContext.save()
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
}

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
                        Button("Save") {
                            createCategoryAndAssign()
                        }
                        .disabled(newCategoryName.isEmpty)
                    }
                } else {
                    Button("New Category") { showingNewCategoryField = true }
                }
            }
            
            Section("Existing Categories") {
                ForEach(categories) { category in
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(Color(category.color))
                        Text(category.name)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { assignToCategory(category) }
                }
            }
            
            Section("Default") {
                Button("Misc (No Category)") { assignToDefault() }
            }
        }
    }
    
    private func createCategoryAndAssign() {
        let category = Category(name: newCategoryName, icon: "folder", color: "gray")
        modelContext.insert(category)
        assignToCategory(category)
    }
    
    private func assignToCategory(_ category: Category) {
        guard let fileName = fileURL.lastPathComponent.lowercased().removingPercentEncoding else { return }
        if fileName.hasSuffix(".ipa") || fileName.hasSuffix(".dylib") || fileName.hasSuffix(".deb") {
            Task {
                do {
                    let appFile = try await FileService.shared.importFile(at: fileURL)
                    appFile.category = category
                    try modelContext.save()
                    dismiss()
                } catch {
                    print("Import failed: \(error)")
                    dismiss()
                }
            }
        } else {
            dismiss()
        }
    }
    
    private func assignToDefault() {
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
        } else {
            dismiss()
        }
    }
}

extension String {
    var removingPercentEncoding: String? {
        return (self as NSString).removingPercentEncoding
    }
}
