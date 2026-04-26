import SwiftUI

struct GeneralView: View {
    @State private var signedApps: [AppFile] = []
    @State private var logs: [AppLog] = []
    
    @State private var selectedSegment = 0
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            ZStack {
                XsignTheme.background.ignoresSafeArea()
                VStack {
                    Picker("Section", selection: $selectedSegment) {
                        Text("Signed").tag(0)
                        Text("Certs").tag(1)
                        Text("Logs").tag(2)
                        Text("Device").tag(3)
                    }.pickerStyle(.segmented).padding()

                    if selectedSegment == 0 { SignedAppsList(apps: signedApps) }
                    else if selectedSegment == 1 { CertificateManagementView() }
                    else if selectedSegment == 2 { LogsView(logs: logs, searchText: $searchText) }
                    else { DeviceManagementView() }
                }.navigationTitle("General")
            }
        }.onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        signedApps = PersistenceService.shared.fetchSignedApps()
        logs = PersistenceService.shared.fetchLogs()
    }
}

struct SignedAppsList: View {
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
        }
        else {
            List(apps) { app in
                HStack {
                    Image(systemName: "app.fill").foregroundColor(XsignTheme.primary)
                    VStack(alignment: .leading) {
                        Text(app.name).foregroundColor(XsignTheme.textPrimary)
                        Text(app.bundleID ?? "").font(.caption).foregroundColor(XsignTheme.textSecondary)
                    }
                    Spacer()
                    Text(app.lastSignedDate?.formatted(date: .numeric, time: .omitted) ?? "").font(.caption2).foregroundColor(XsignTheme.textSecondary)
                }.listRowBackground(XsignTheme.surface)
            }.listStyle(.plain)
        }
    }
}

struct LogsView: View {
    let logs: [AppLog]
    @Binding var searchText: String
    var body: some View {
        VStack {
            TextField("Search...", text: $searchText).padding(8).background(XsignTheme.surface).cornerRadius(8).padding(.horizontal)
            List(logs.filter { searchText.isEmpty || $0.message.contains(searchText) }) { log in
                VStack(alignment: .leading) {
                    Text(log.category).font(.system(size: 8, weight: .bold)).foregroundColor(XsignTheme.textSecondary)
                    Text(log.message).font(.subheadline).foregroundColor(XsignTheme.textPrimary)
                }.listRowBackground(XsignTheme.surface)
            }.listStyle(.plain)
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
        }.listStyle(.insetGrouped)
    }
}
