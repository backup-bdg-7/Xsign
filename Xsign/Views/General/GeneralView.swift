import SwiftUI

struct GeneralView: View {
    @State private var signedApps: [AppFile] = []
    @State private var logs: [AppLog] = []
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented picker at top
                Picker("Section", selection: $selectedSegment) {
                    Text("Signed").tag(0)
                    Text("Certs").tag(1)
                    Text("Logs").tag(2)
                    Text("Device").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content below picker
                ZStack {
                    XsignTheme.background.ignoresSafeArea()
                    
                    switch selectedSegment {
                    case 0: SignedAppsListView(apps: signedApps)
                    case 1: CertificateManagementView()
                    case 2: LogsListView(logs: logs)
                    default: DeviceManagementView()
                    }
                }
            }
            .navigationTitle("General")
            .onAppear { loadData() }
        }
    }
    
    private func loadData() {
        signedApps = PersistenceService.shared.fetchSignedApps()
        logs = PersistenceService.shared.fetchLogs()
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
