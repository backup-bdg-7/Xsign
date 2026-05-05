import SwiftUI
import SwiftData

struct GeneralView: View {
    @Query private var certificates: [Certificate]
    @State private var selectedCertIndex: Int = 0
    @State private var showingCertificatesView = false
    @State private var showingSigningOptions = false
    @State private var showingResetView = false
    @State private var showingAboutView = false
    @State private var showingLogsView = false
    @State private var showingDeviceView = false
    
    var selectedCertificate: Certificate? {
        guard selectedCertIndex >= 0, selectedCertIndex < certificates.count else {
            return nil
        }
        return certificates[selectedCertIndex]
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Certificates Section
                Section {
                    if let cert = selectedCertificate {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text(cert.name)
                                    .font(.headline)
                                Text(cert.commonName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingCertificatesView = true
                        }
                    } else {
                        Text("No Certificate")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: { showingCertificatesView = true }) {
                        Label("Certificates", systemImage: "checkmark.seal")
                    }
                } footer: {
                    Text("Add and manage certificates used for signing applications.")
                }
                
                // Features Section
                Section {
                    Button(action: { showingSigningOptions = true }) {
                        Label("Signing Options", systemImage: "signature")
                    }
                } header: {
                    Text("Features")
                } footer: {
                    Text("Configure the app's signing options.")
                }
                
                // Logs Section
                Section {
                    Button(action: { showingLogsView = true }) {
                        Label("View Logs", systemImage: "doc.text")
                    }
                } header: {
                    Text("Logs")
                } footer: {
                    Text("View all application logs.")
                }
                
                // Device Info Section
                Section {
                    Button(action: { showingDeviceView = true }) {
                        Label("Device Information", systemImage: "iphone")
                    }
                } header: {
                    Text("Device")
                } footer: {
                    Text("View device information and status.")
                }
                
                // Directories Section
                Section {
                    Button("Open Documents") {
                        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                            // Use UIDocumentInteractionController or show in app
                            let activityVC = UIActivityViewController(activityItems: [documentsURL], applicationActivities: nil)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootVC = windowScene.keyWindow?.rootViewController {
                                rootVC.present(activityVC, animated: true)
                            }
                        }
                    }
                    Button("Open Apps") {
                        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let appsDir = documentsURL.appendingPathComponent("apps", isDirectory: true)
                            try? FileManager.default.createDirectory(at: appsDir, withIntermediateDirectories: true)
                            let activityVC = UIActivityViewController(activityItems: [appsDir], applicationActivities: nil)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootVC = windowScene.keyWindow?.rootViewController {
                                rootVC.present(activityVC, animated: true)
                            }
                        }
                    }
                    Button("Open Certificates") {
                        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let certsDir = documentsURL.appendingPathComponent("certificates", isDirectory: true)
                            try? FileManager.default.createDirectory(at: certsDir, withIntermediateDirectories: true)
                            let activityVC = UIActivityViewController(activityItems: [certsDir], applicationActivities: nil)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootVC = windowScene.keyWindow?.rootViewController {
                                rootVC.present(activityVC, animated: true)
                            }
                        }
                    }
                    Button("Open Signed Apps") {
                        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let signedDir = documentsURL.appendingPathComponent("signed", isDirectory: true)
                            try? FileManager.default.createDirectory(at: signedDir, withIntermediateDirectories: true)
                            let activityVC = UIActivityViewController(activityItems: [signedDir], applicationActivities: nil)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootVC = windowScene.keyWindow?.rootViewController {
                                rootVC.present(activityVC, animated: true)
                            }
                        }
                    }
                } header: {
                    Text("Directories")
                } footer: {
                    Text("All of the app's files are contained in the documents directory, here are some quick links to these.")
                }
                
                // Reset Section
                Section {
                    Button(action: { showingResetView = true }) {
                        Label("Reset", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                } footer: {
                    Text("Reset the application's sources, certificates, apps, and general contents.")
                }
                
                // About Section
                Section {
                    Button(action: { showingAboutView = true }) {
                        Label("About XSign", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("General")
            .sheet(isPresented: $showingCertificatesView) {
                NavigationStack {
                    CertificateManagementView()
                        .navigationTitle("Certificates")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showingCertificatesView = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingSigningOptions) {
                NavigationStack {
                    SigningOptionsView(options: .constant(SigningOptions()))
                        .navigationTitle("Signing Options")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showingSigningOptions = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingLogsView) {
                NavigationStack {
                    LogsView()
                        .navigationTitle("Logs")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showingLogsView = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingDeviceView) {
                NavigationStack {
                    DeviceManagementView()
                        .navigationTitle("Device Info")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showingDeviceView = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingResetView) {
                NavigationStack {
                    ResetView()
                        .navigationTitle("Reset")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showingResetView = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingAboutView) {
                NavigationStack {
                    AboutView()
                        .navigationTitle("About")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showingAboutView = false }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - ResetView
struct ResetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation = false
    
    var body: some View {
        List {
            Section {
                Button("Reset All Data") {
                    showConfirmation = true
                }
                .foregroundColor(.red)
                .confirmationDialog(
                    "Are you sure you want to reset all data?",
                    isPresented: $showConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Reset Everything", role: .destructive) {
                        resetAllData()
                        dismiss()
                    }
                } message: {
                    Text("This will delete all certificates, apps, and settings. This action cannot be undone.")
                }
            } footer: {
                Text("This will delete all certificates, apps, and settings.")
            }
        }
    }
    
    private func resetAllData() {
        let persistence = PersistenceService.shared
        let context = persistence.context
        
        // Delete all AppFiles
        let appFiles = persistence.fetchSignedApps()
        for file in appFiles {
            if FileManager.default.fileExists(atPath: file.filePath.path) {
                try? FileManager.default.removeItem(at: file.filePath)
            }
            context.delete(file)
        }
        
        // Delete all Certificates
        let descriptor = FetchDescriptor<Certificate>()
        if let certificates = try? context.fetch(descriptor) {
            for cert in certificates {
                context.delete(cert)
            }
        }
        
        // Delete all Categories
        let catDescriptor = FetchDescriptor<Category>()
        if let categories = try? context.fetch(catDescriptor) {
            for cat in categories {
                context.delete(cat)
            }
        }
        
        // Delete all Logs
        let logDescriptor = FetchDescriptor<AppLog>()
        if let logs = try? context.fetch(logDescriptor) {
            for log in logs {
                context.delete(log)
            }
        }
        
        // Reset UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        persistence.save()
        persistence.log(level: .info, category: "System", message: "All data has been reset")
    }
}

// MARK: - AboutView  
struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        // App icon
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "signature")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            )
                        
                        Text("XSign")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            
            Section(header: Text("Feedback")) {
                Button("Submit Feedback") {
                    // Open GitHub issues
                }
                Button("GitHub Repository") {
                    // Open GitHub repo
                }
            }
        }
    }
}


struct SignedAppsListView: View {
    let apps: [AppFile]
    var body: some View {
        if apps.isEmpty {
            VStack {
                Image(systemName: "app.fill")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No Apps")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(apps) { app in
                HStack {
                    Image(systemName: "app.fill").foregroundColor(XsignTheme.primary)
                    VStack(alignment: .leading) {
                        Text(app.name).foregroundColor(XsignTheme.textPrimary)
                        Text(app.bundleID ?? "").font(.caption).foregroundColor(XsignTheme.textSecondary)
                    }
                    Spacer()
                    Text(app.lastSignedDate?.formatted(date: .numeric, time: .omitted) ?? "")
                        .font(.caption2)
                        .foregroundColor(XsignTheme.textSecondary)
                }
                .listRowBackground(XsignTheme.surface)
            }
            .listStyle(.plain)
        }
    }
}

struct LogsListView: View {
    let logs: [AppLog]
    @State private var searchText = ""
    @State private var selectedLevel: LogLevel?
    
    var filteredLogs: [AppLog] {
        logs.filter { log in
            let matchesSearch = searchText.isEmpty ||
                log.message.contains(searchText) ||
                log.category.contains(searchText)
            let matchesLevel = selectedLevel == nil || log.level == selectedLevel
            return matchesSearch && matchesLevel
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Menu {
                    Button("All") { selectedLevel = nil }
                    Divider()
                    ForEach([LogLevel.info, .success, .warning, .error], id: \.self) { level in
                        Button(level.rawValue.capitalized) { selectedLevel = level }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(selectedLevel == nil ? .secondary : XsignTheme.primary)
                }
            }
            .padding(.horizontal)
            
            if filteredLogs.isEmpty {
                VStack(spacing: 16) {
                    Text("No Logs")
                        .font(.headline)
                        .foregroundColor(XsignTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredLogs) { log in
                        LogRow(log: log)
                            .listRowBackground(XsignTheme.surface)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct DeviceManagementView: View {
    var body: some View {
        List {
            Section("Info") {
                InfoRow(label: "Model", value: UIDevice.current.model)
                InfoRow(label: "OS", value: UIDevice.current.systemVersion)
            }
        }
        .listStyle(.insetGrouped)
    }
}

extension FileManager {
    var documentsDirectory: URL {
        urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
