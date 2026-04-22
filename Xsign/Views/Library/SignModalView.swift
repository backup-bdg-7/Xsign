import SwiftUI
import SwiftData

struct SignModalView: View {
    let appFile: AppFile

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Certificate.name) private var certificates: [Certificate]

    @State private var selectedCertificateID: UUID?
    @State private var isSigning = false
    @State private var showSuccess = false
    @State private var signedIPAURL: URL?

    // Modification Overrides
    @State private var newBundleID = ""
    @State private var newBundleName = ""
    @State private var newVersion = ""
    @State private var modifyEnabled = false
    @State private var selectedDylibs: Set<UUID> = []

    @Query(filter: #Predicate<AppFile> { $0.type == .dylib }) private var availableDylibs: [AppFile]

    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    if isSigning {
                        VStack(spacing: 20) {
                            ProgressView().scaleEffect(2)
                            Text("Signing & Injecting...")
                                .foregroundColor(XsignTheme.textPrimary)
                        }
                    } else if showSuccess {
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 80)).foregroundColor(XsignTheme.success)
                            Text("Ready!").font(.title2).fontWeight(.bold).foregroundColor(XsignTheme.textPrimary)
                            Button("Install Now") { startInstallation() }
                                .buttonStyle(.borderedProminent).tint(XsignTheme.success)
                        }
                    } else {
                        Form {
                            Section("Certificate") {
                                if certificates.isEmpty {
                                    NavigationLink("Import Certificate") { ImportCertificateView() }
                                } else {
                                    Picker("Select", selection: $selectedCertificateID) {
                                        Text("None").tag(nil as UUID?)
                                        ForEach(certificates) { cert in
                                            Text(cert.name).tag(cert.id as UUID?)
                                        }
                                    }
                                }
                            }

                            Section(header: Toggle("Modify App Info", isOn: $modifyEnabled)) {
                                if modifyEnabled {
                                    TextField("Name", text: $newBundleName)
                                    TextField("Bundle ID", text: $newBundleID)
                                    TextField("Version", text: $newVersion)
                                }
                            }

                            Section("Inject Dylibs") {
                                ForEach(availableDylibs) { dylib in
                                    Toggle(dylib.name, isOn: Binding(
                                        get: { selectedDylibs.contains(dylib.id) },
                                        set: { if $0 { selectedDylibs.insert(dylib.id) } else { selectedDylibs.remove(dylib.id) } }
                                    ))
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)

                        Button(action: startSigning) {
                            Text("Sign App").fontWeight(.bold).frame(maxWidth: .infinity).padding()
                                .background(selectedCertificateID == nil ? Color.gray : XsignTheme.primary)
                                .foregroundColor(.white).cornerRadius(12)
                        }.disabled(selectedCertificateID == nil).padding()
                    }
                }
            }
            .navigationTitle("Sign IPA")
            .toolbar { Button("Close") { dismiss() } }
        }
        .onAppear {
            newBundleID = appFile.bundleID ?? ""
            newBundleName = appFile.name
            newVersion = appFile.version ?? ""
        }
    }

    private func startSigning() {
        guard let certID = selectedCertificateID,
              let certificate = certificates.first(where: { $0.id == certID }) else { return }

        isSigning = true

        let dylibPaths = availableDylibs.filter { selectedDylibs.contains($0.id) }.map { $0.filePath.path }
        let options = SigningService.SigningOptions(
            bundleID: modifyEnabled ? newBundleID : nil,
            bundleName: modifyEnabled ? newBundleName : nil,
            bundleVersion: modifyEnabled ? newVersion : nil,
            dylibPaths: dylibPaths.isEmpty ? nil : dylibPaths
        )

        Task {
            do {
                let url = try await SigningService.shared.sign(appFile: appFile, certificate: certificate, options: options)
                await MainActor.run {
                    self.signedIPAURL = url
                    withAnimation {
                        isSigning = false
                        showSuccess = true
                    }
                }
            } catch {
                await MainActor.run { isSigning = false }
            }
        }
    }

    private func startInstallation() {
        guard let url = signedIPAURL else { return }
        Task {
            if let installURL = try? await LocalServerService.shared.startServer(
                for: url,
                bundleID: modifyEnabled ? newBundleID : (appFile.bundleID ?? ""),
                version: modifyEnabled ? newVersion : (appFile.version ?? ""),
                name: modifyEnabled ? newBundleName : appFile.name
            ) {
                UIApplication.shared.open(installURL)
            }
            dismiss()
        }
    }
}
