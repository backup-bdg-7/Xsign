import SwiftUI
import SwiftData

// MARK: - XSignView
// Displays signed apps similar to Feather's Library view
struct XSignView: View {
    @Query(sort: \AppFile.lastSignedDate, order: .reverse) private var signedApps: [AppFile]
    @State private var searchText = ""
    @State private var selectedAppIDs: Set<UUID> = []
    @State private var editMode: EditMode = .inactive
    
    var filteredApps: [AppFile] {
        if searchText.isEmpty {
            return signedApps.filter { $0.isSigned || $0.signatureStatus == .signed }
        } else {
            return signedApps.filter { file in
                (file.isSigned || file.signatureStatus == .signed) &&
                (file.name.localizedCaseInsensitiveContains(searchText) ||
                 (file.bundleID?.localizedCaseInsensitiveContains(searchText) ?? false))
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if filteredApps.isEmpty {
                    emptyStateView
                } else {
                    contentList
                }
            }
            .navigationTitle("XSign")
            .searchable(text: $searchText, placement: .platform())
            .scrollDismissesKeyboard(.interactively)
            .toolbar { toolbarContent }
            .environment(\.editMode, $editMode)
            .onChange(of: editMode) { mode in
                if mode == .inactive {
                    selectedAppIDs.removeAll()
                }
            }
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "signature")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Signed Apps")
                .font(.headline)
                .foregroundColor(XsignTheme.textSecondary)
            Text("Sign apps from the Library tab")
                .font(.caption)
                .foregroundColor(XsignTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var contentList: some View {
        List {
            Section("Signed Apps (\(filteredApps.count))") {
                ForEach(filteredApps) { file in
                    NavigationLink(destination: AppDetailView(appFile: file)) {
                        SignedAppRow(appFile: file)
                            .contentShape(Rectangle())
                    }
                    .swipeActions {
                        Button(action: {
                            // Resign action
                        }) {
                            Label("Sign", systemImage: "signature")
                        }
                        .tint(.blue)
                        
                        Button(role: .destructive) {
                            deleteFile(file)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button(action: {
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
                            // Install action
                        }) {
                            Label("Install", systemImage: "arrow.down.circle")
                        }
                        
                        Button(action: {
                            // Share action
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        if index < filteredApps.count {
                            deleteFile(filteredApps[index])
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
            }
        }
        
        ToolbarItem(placement: .cancellationAction) {
            EditButton()
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
        } catch {
            print("Failed to delete file: \(error)")
        }
    }
    
    private func bulkDeleteSelectedApps() {
        let selectedFiles = filteredApps.filter { file in
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

// MARK: - SignedAppRow
struct SignedAppRow: View {
    let appFile: AppFile
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(XsignTheme.primary.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "doc.badge.gearshape")
                        .foregroundColor(XsignTheme.primary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(appFile.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let bundleID = appFile.bundleID {
                    Text(bundleID)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    if let version = appFile.version {
                        Text("v\(version)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                    
                    if let date = appFile.lastSignedDate {
                        Text(date, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}
