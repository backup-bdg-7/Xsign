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
    
    var filteredFiles: [AppFile] {
        guard let id = selectedCategoryID else { return Array(appFiles) }
        return appFiles.filter { $0.category?.id == id }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryPills
                Divider()
                content
            }
            .navigationTitle("Library")
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingCategoryCreator) { createCategorySheet }
            .fileImporter(isPresented: $showingImportPicker, allowedContentTypes: [.ipa, .dylib, .deb]) { result in
                if let url = try? result.get() {
                    importedFileURL = url
                    showingCategoryPicker = true
                }
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
    
    var categoryPills: some View {
        Group {
            if !categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryPill(name: "All", icon: "square.grid.2x2", colorName: "gray", isSelected: selectedCategoryID == nil)
                            .onTapGesture { selectedCategoryID = nil }
                        ForEach(categories) { cat in
                            CategoryPill(name: cat.name, icon: cat.icon, colorName: cat.color, isSelected: selectedCategoryID == cat.id)
                                .onTapGesture { selectedCategoryID = cat.id }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    @ViewBuilder
    var content: some View {
        if filteredFiles.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
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
                        NavigationLink(destination: AppDetailView(appFile: file)) {
                            AppFileCard(appFile: file)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button { showingCategoryCreator = true } label: {
                Image(systemName: "folder.badge.plus")
            }
            Button { showingImportPicker = true } label: {
                Image(systemName: "plus")
            }
        }
    }
    
    var createCategorySheet: some View {
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
}
