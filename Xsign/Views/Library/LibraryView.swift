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
    
    // Search and selection states like Feather
    @State private var searchText = ""
    @State private var selectedAppIDs: Set<UUID> = []
    @State private var editMode: EditMode = .inactive
    
    var filteredFiles: [AppFile] {
        guard let id = selectedCategoryID else { return Array(appFiles) }
        return appFiles.filter { $0.category?.id == id }
    }
    
    var searchedFiles: [AppFile] {
        let baseFiles = filteredFiles
        if searchText.isEmpty {
            return baseFiles
        } else {
            return baseFiles.filter { file in
                file.name.localizedCaseInsensitiveContains(searchText) ||
                (file.bundleID?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryPills
                Divider()
                content
            }
            .navigationTitle("Library")
            .searchable(text: $searchText)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                if editMode.isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete (\(selectedAppIDs.count))") {
                            bulkDeleteSelectedApps()
                        }
                        .disabled(selectedAppIDs.isEmpty)
                    }
                } else {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingImportPicker = true
                        } label: {
                            Label("Import Files", systemImage: "plus")
                        }
                    }
                    ToolbarItem(placement: .secondaryAction) {
                        Button {
                            showingCategoryCreator = true
                        } label: {
                            Label("Categories", systemImage: "folder.badge.gearshape")
                        }
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    EditButton()
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingImportPicker) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.ipa, .dylib, .deb, .tipa],
                    allowsMultipleSelection: true,
                    onDocumentsPicked: { urls in
                        guard !urls.isEmpty else { return }
                        for url in urls {
                            handleImportedFile(url)
                        }
                    }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingCategoryPicker) {
                NavigationStack {
                    List {
                        Section("Select Category for Imported File") {
                            Button("None (No Category)") {
                                // Assign no category
                                if let url = importedFileURL,
                                   let fileName = url.lastPathComponent as String?,
                                   let appFile = PersistenceService.shared.fetchAppFile(by: fileName) {
                                    appFile.category = nil
                                    PersistenceService.shared.save()
                                }
                                showingCategoryPicker = false
                            }
                            ForEach(categories) { cat in
                                Button(cat.name) {
                                    // Assign selected category to the imported file
                                    if let url = importedFileURL,
                                       let fileName = url.lastPathComponent as String?,
                                       let appFile = PersistenceService.shared.fetchAppFile(by: fileName) {
                                        appFile.category = cat
                                        PersistenceService.shared.save()
                                    }
                                    showingCategoryPicker = false
                                }
                            }
                        }
                    }
                    .navigationTitle("Choose Category")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingCategoryPicker = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCategoryCreator) {
                CategoryManagementView()
            }
            .onChange(of: editMode) { mode in
                if mode == .inactive {
                    selectedAppIDs.removeAll()
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
        if searchedFiles.isEmpty {
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
            List {
                ForEach(searchedFiles) { file in
                    HStack {
                        if editMode.isEditing {
                            Image(systemName: selectedAppIDs.contains(file.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedAppIDs.contains(file.id) ? XsignTheme.primary : .secondary)
                                .onTapGesture {
                                    if selectedAppIDs.contains(file.id) {
                                        selectedAppIDs.remove(file.id)
                                    } else {
                                        selectedAppIDs.insert(file.id)
                                    }
                                }
                        }
                        
                        NavigationLink(destination: AppDetailView(appFile: file)) {
                            AppFileCard(appFile: file)
                                .contentShape(Rectangle())
                        }
                        .disabled(editMode.isEditing) // Disable navigation in edit mode
                    }
                    .swipeActions {
                        if !editMode.isEditing {
                            Button(role: .destructive) {
                                deleteFile(file)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
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
    
    private func handleImportedFile(_ url: URL) {
        // Handle the imported file - process ipa, dylib, deb files
        let fileExtension = url.pathExtension.lowercased()
        
        do {
            let data = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            let fileType: FileType
            
            switch fileExtension {
            case "ipa":
                fileType = .ipa
            case "dylib":
                fileType = .dylib
            case "deb":
                fileType = .deb
            default:
                return
            }
            
            // Create AppFile record
            let appFile = AppFile(
                name: fileName,
                fileName: fileName,
                relativePath: "imports/\(fileName)",
                type: fileType,
                size: Int64(data.count),
                creationDate: Date(),
                isSigned: false,
                signatureStatus: .unsigned
            )
            
            // If categories exist, prompt user to select one
            if !categories.isEmpty {
                // Set the imported file URL to trigger category picker
                importedFileURL = url
                showingCategoryPicker = true
                // Store the file temporarily and handle category assignment in the sheet
                PersistenceService.shared.context.insert(appFile)
                // We'll set the category after user picks one
            } else {
                // No categories, just save
                PersistenceService.shared.context.insert(appFile)
            }
            
            // Save file to documents directory
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let importsDir = documentsDir.appendingPathComponent("imports", isDirectory: true)
            
            if !FileManager.default.fileExists(atPath: importsDir.path) {
                try FileManager.default.createDirectory(at: importsDir, withIntermediateDirectories: true)
            }
            
            let destinationURL = importsDir.appendingPathComponent(fileName)
            try data.write(to: destinationURL)
            
            PersistenceService.shared.save()
            
        } catch {
            print("Failed to import file: \(error)")
        }
    }
    
    private func deleteCategory(_ cat: Category) {
        // Set category to nil for all apps in this category
        if let apps = cat.appFiles {
            for app in apps {
                app.category = nil
            }
        }
        // Delete the category
        PersistenceService.shared.context.delete(cat)
        PersistenceService.shared.save()
    }
    
    private func deleteFile(_ file: AppFile) {
        do {
            // Delete the physical file
            if FileManager.default.fileExists(atPath: file.filePath.path) {
                try FileManager.default.removeItem(at: file.filePath)
            }
            // Delete from database
            PersistenceService.shared.context.delete(file)
            PersistenceService.shared.save()
        } catch {
            print("Failed to delete file: \(error)")
        }
    }
    
    private func bulkDeleteSelectedApps() {
        let selectedFiles = searchedFiles.filter { file in
            guard let id = file.id as UUID? else { return false }
            return selectedAppIDs.contains(id)
        }
        
        for file in selectedFiles {
            deleteFile(file)
        }
        
        selectedAppIDs.removeAll()
        editMode = .inactive
    }
}
