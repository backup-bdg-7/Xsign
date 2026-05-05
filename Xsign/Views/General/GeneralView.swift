import SwiftUI
import SwiftData

struct GeneralView: View {
    @Query private var certificates: [Certificate]
    @State private var selectedCertIndex: Int = 0
    @State private var showingCertificatesView = false
    @State private var showingSigningOptions = false
    @State private var showingAppIconView = false
    @State private var showingResetView = false
    @State private var showingAboutView = false
    
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
                Section(header: Text("Certificates")) {
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
                Section(header: Text("Features")) {
                    Button(action: { showingSigningOptions = true }) {
                        Label("Signing Options", systemImage: "signature")
                    }
                    
                    Button(action: { showingAppIconView = true }) {
                        Label("App Icon", systemImage: "app.badge")
                    }
                } footer: {
                    Text("Configure the app's signing options and appearance.")
                }
                
                // Directories Section
                Section(header: Text("Directories")) {
                    Button("Open Documents") {
                        UIApplication.shared.open(FileManager.default.documentsDirectory)
                    }
                    Button("Open Certificates") {
                        let certsDir = FileManager.default.documentsDirectory.appendingPathComponent("certificates", isDirectory: true)
                        UIApplication.shared.open(certsDir)
                    }
                    Button("Open Imports") {
                        let importsDir = FileManager.default.documentsDirectory.appendingPathComponent("imports", isDirectory: true)
                        UIApplication.shared.open(importsDir)
                    }
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
            .navigationTitle("Settings")
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
    var body: some View {
        List {
            Section {
                Button("Reset All Data") {
                    // Implement reset functionality
                }
                .foregroundColor(.red)
            } footer: {
                Text("This will delete all certificates, apps, and settings.")
            }
        }
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

struct LogRow: View {
    let log: AppLog
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconForLevel(log.level))
                .foregroundColor(colorForLevel(log.level))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(log.category)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(XsignTheme.textSecondary)
                    Spacer()
                    Text(log.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(XsignTheme.textSecondary)
                }
                Text(log.message)
                    .font(.subheadline)
                    .foregroundColor(XsignTheme.textPrimary)
                    .lineLimit(3)
                if let details = log.details {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(XsignTheme.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForLevel(_ level: LogLevel) -> String {
        switch level {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    
    private func colorForLevel(_ level: LogLevel) -> Color {
        switch level {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
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
