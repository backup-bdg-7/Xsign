import SwiftUI
import SwiftData

struct GeneralView: View {
    @Query(sort: \AppLog.timestamp, order: .reverse) private var logs: [AppLog]
    @Query(filter: #Predicate<AppFile> { $0.isSigned == true }) private var signedApps: [AppFile]

    @State private var selectedSegment = 0
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()

                VStack {
                    Picker("Section", selection: $selectedSegment) {
                        Text("Signed Apps").tag(0)
                        Text("Logs").tag(1)
                        Text("Device").tag(2)
                    }
                    pickerStyle(.segmented)
                    .padding()

                    if selectedSegment == 0 {
                        SignedAppsList(apps: signedApps)
                    } else if selectedSegment == 1 {
                        LogsView(logs: logs, searchText: $searchText)
                    } else {
                        DeviceManagementView()
                    }
                }
            }
            .navigationTitle("General")
        }
    }
}

struct SignedAppsList: View {
    let apps: [AppFile]

    var body: some View {
        if apps.isEmpty {
            ContentUnavailableView("No Signed Apps", systemImage: "checkmark.seal", description: Text("Apps you sign will appear here."))
        } else {
            List(apps) { app in
                HStack {
                    Image(systemName: "app.fill")
                        .foregroundColor(XsignTheme.primary)
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

struct LogsView: View {
    let logs: [AppLog]
    @Binding var searchText: String

    var filteredLogs: [AppLog] {
        logs.filter { searchText.isEmpty || $0.message.localizedCaseInsensitiveContains(searchText) || $0.category.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack {
            TextField("Search logs...", text: $searchText)
                .padding(8)
                .background(XsignTheme.surface)
                .cornerRadius(8)
                .padding(.horizontal)

            List(filteredLogs) { log in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        LogLevelBadge(level: log.level)
                        Text(log.category.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(XsignTheme.textSecondary)
                        Spacer()
                        Text(log.timestamp.formatted(date: .omitted, time: .standard))
                            .font(.system(size: 10))
                            .foregroundColor(XsignTheme.textSecondary)
                    }
                    Text(log.message)
                        .font(.subheadline)
                        .foregroundColor(XsignTheme.textPrimary)
                    if let details = log.details {
                        Text(details)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(XsignTheme.textSecondary)
                            .padding(4)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(4)
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(XsignTheme.surface)
            }
            .listStyle(.plain)
        }
    }
}

struct LogLevelBadge: View {
    let level: LogLevel

    var body: some View {
        Text(level.rawValue.uppercased())
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(2)
    }

    var color: Color {
        switch level {
        case .info: return .blue
        case .success: return XsignTheme.success
        case .warning: return .orange
        case .error: return XsignTheme.error
        }
    }
}

struct DeviceManagementView: View {
    var body: some View {
        List {
            Section("Connected Device") {
                InfoRow(label: "Model", value: "iPhone 15 Pro")
                InfoRow(label: "iOS Version", value: "17.4")
                InfoRow(label: "UDID", value: "00008101-000C1D2E...")
            }
            .listRowBackground(XsignTheme.surface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}
