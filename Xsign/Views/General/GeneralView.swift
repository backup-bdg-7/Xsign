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
                        Text("Signed").tag(0)
                        Text("Certificates").tag(1)
                        Text("Logs").tag(2)
                        Text("Device").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    if selectedSegment == 0 {
                        SignedAppsList(apps: signedApps)
                    } else if selectedSegment == 1 {
                        CertificateManagementView()
                    } else if selectedSegment == 2 {
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
