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
    @State private var refreshID = UUID() // Force refresh after delete
    
    // Search and selection states like Feather
    @State private var searchText = ""
    @State private var selectedAppIDs: Set<UUID> = []
    @State private var editMode: EditMode = .inactive
    
    // Rename states
    @State private var showingRenameSheet = false
    @State private var fileToRename: AppFile?
    @State private var newFileName = ""
    @State private var showingSignModal = false
    @State private var fileToSign: AppFile?
    
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
                    .id(refreshID) // Force refresh after delete
            }
            .navigationTitle("Library")
            .searchable(text: $searchText)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if editMode.isEditing {
                        Button("Delete (\(selectedAppIDs.count))") {
                            bulkDeleteSelectedApps()
                        }
                        .disabled(selectedAppIDs.isEmpty)
                    } else {
                        Button {
                            showingImportPicker = true
                        } label: {
                            Label("Import Files", systemImage: "plus")
                        }
                        Button {
                            showingCategoryCreator = true
                        } label: {
                            Label("Categories", systemImage: "folder.badge.gearshape")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
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
	            .sheet(isPresented: $showingSignModal) {
                if let file = fileToSign {
                    SignModalView(appFile: file)
                }
            }
            .sheet(isPresented: $showingRenameSheet) {
                NavigationStack {
                    Form {
                        Section("Rename File") {
                            TextField("New file name", text: $newFileName)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Section {
                            Button("Rename") {
                                renameFile()
                                showingRenameSheet = false
                            }
                            .disabled(newFileName.isEmpty)
                        }
                    }
                    .navigationTitle("Rename")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingRenameSheet = false }
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
                        
                        NavigationLink(destination: 
                            file.type == .dylib || file.type == .deb 
                            ? AnyView(FileInfoView(appFile: file)) 
                            : AnyView(AppDetailView(appFile: file))
                        ) {
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
                    .contextMenu {
                        if !editMode.isEditing {
                            Button {
                                fileToSign = file
                                showingSignModal = true
                            } label: {
                                Label("Sign", systemImage: "signature")
                            }
                            
                            Button {
                                fileToRename = file
                                newFileName = file.name
                                showingRenameSheet = true
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            
                            Button {
                                // Duplicate the file
                                duplicateFile(file)
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            
                            Divider()
                            
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
        // Handle the imported file - process ipa, dylib, deb, tipa files
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
            case "tipa":
                fileType = .tipa
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
            try FileManager.default.createDirectory(at: importsDir, withIntermediateDirectories: true)
            let destinationURL = importsDir.appendingPathComponent(fileName)
            try data.write(to: destinationURL)
            
            // Insert and save the AppFile
            PersistenceService.shared.context.insert(appFile)
            PersistenceService.shared.save()
            
            // If categories exist, prompt user to select one
            if !categories.isEmpty {
                importedFileURL = url
                showingCategoryPicker = true
            }
            
            PersistenceService.shared.log(level: .info, category: "Import", message: "Imported file: \(fileName)")
        } catch {
            print("Failed to import file: \(error)")
            PersistenceService.shared.log(level: .error, category: "Import", message: "Failed to import file", details: error.localizedDescription)
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
    
    private func renameFile() {
        guard let file = fileToRename else { return }
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let oldURL = documentsDir.appendingPathComponent(file.relativePath)
        let newURL = documentsDir.appendingPathComponent("imports/\(newFileName)")
        
        do {
            try FileManager.default.moveItem(at: oldURL, to: newURL)
            file.name = newFileName
            file.fileName = newFileName
            file.relativePath = "imports/\(newFileName)"
            PersistenceService.shared.save()
            refreshID = UUID()
        } catch {
            print("Failed to rename file: \(error)")
        }
        
        newFileName = ""
        fileToRename = nil
    }
    
    private func duplicateFile(_ file: AppFile) {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let oldURL = documentsDir.appendingPathComponent(file.relativePath)
        let fileName = "\(file.name)_copy.\(file.type.rawValue)"
        let newURL = documentsDir.appendingPathComponent("imports/\(fileName)")
        
        do {
            // Copy the physical file
            try FileManager.default.copyItem(at: oldURL, to: newURL)
            
            // Create new AppFile
            let newFile = AppFile(
                name: "\(file.name) (Copy)",
                fileName: fileName,
                relativePath: "imports/\(fileName)",
                type: file.type,
                size: file.size,
                creationDate: Date(),
                bundleID: file.bundleID,
                version: file.version,
                build: file.build,
                isSigned: file.isSigned,
                signatureStatus: file.signatureStatus,
                entitlements: file.entitlements,
                category: file.category
            )
            
            PersistenceService.shared.context.insert(newFile)
            PersistenceService.shared.save()
            refreshID = UUID()
            
            PersistenceService.shared.log(level: .info, category: "Duplicate", message: "Duplicated file: \(file.name)")
        } catch {
            print("Failed to duplicate file: \(error)")
        }
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
            // Force refresh
            refreshID = UUID()
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
        // Force refresh
        refreshID = UUID()
    }
}
