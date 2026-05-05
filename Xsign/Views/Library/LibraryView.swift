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
                        Button { showingCategoryCreator = true } label: {
                            Image(systemName: "folder.badge.plus")
                        }
                        Menu {
                            Button("Import from Files") {
                                showingImportPicker = true
                            }
                            Button("Import from URL") {
                                // Handle URL import
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    EditButton()
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingCategoryCreator) { createCategorySheet }
            .sheet(isPresented: $showingImportPicker) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.ipa, .dylib, .deb, .tipa],
                    allowsMultipleSelection: true,
                    onDocumentsPicked: { urls in
                        guard !urls.isEmpty else { return }
                        // Handle multiple file imports
                        for url in urls {
                            importedFileURL = url
                            // Process the imported file
                            handleImportedFile(url)
                        }
                    }
                )
                .ignoresSafeArea()
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
                            HStack(spacing: 4) {
                                CategoryPill(name: cat.name, icon: cat.icon, colorName: cat.color, isSelected: selectedCategoryID == cat.id)
                                    .onTapGesture { selectedCategoryID = cat.id }
                                
                                if editMode == .active {
                                    Button(action: { deleteCategory(cat) }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                }
                            }
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
                    NavigationLink(destination: AppDetailView(appFile: file)) {
                        AppFileCard(appFile: file)
                            .contentShape(Rectangle())
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            deleteFile(file)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button(action: { 
                            // Add to selection for bulk delete
                            if let id = file.id as UUID? {
                                if selectedAppIDs.contains(id) {
                                    selectedAppIDs.remove(id)
                                } else {
                                    selectedAppIDs.insert(id)
                                }
                            }
                        }) {
                            Label("Select", systemImage: "checkmark.circle")
                        }
                        Button(action: { 
                            // Sign action
                        }) {
                            Label("Sign", systemImage: "signature")
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        if index < searchedFiles.count {
                            deleteFile(searchedFiles[index])
                        }
                    }
                }
            }
        }
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if editMode.isEditing {
                Button("Delete (\(selectedAppIDs.count))") {
                    bulkDeleteSelectedApps()
                }
                .disabled(selectedAppIDs.isEmpty)
            } else {
                Button { showingCategoryCreator = true } label: {
                    Image(systemName: "folder.badge.plus")
                }
                Menu {
                    Button("Import from Files") {
                        showingImportPicker = true
                    }
                    Button("Import from URL") {
                        // Handle URL import
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        
        ToolbarItem(placement: .cancellationAction) {
            EditButton()
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
            
            // Save file to documents directory
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let importsDir = documentsDir.appendingPathComponent("imports", isDirectory: true)
            
            if !FileManager.default.fileExists(atPath: importsDir.path) {
                try FileManager.default.createDirectory(at: importsDir, withIntermediateDirectories: true)
            }
            
            let destinationURL = importsDir.appendingPathComponent(fileName)
            try data.write(to: destinationURL)
            
            PersistenceService.shared.context.insert(appFile)
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
