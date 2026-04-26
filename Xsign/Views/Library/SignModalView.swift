import SwiftUI
import SwiftData

struct SignModalView: View {
    let appFile: AppFile

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Certificate.name) private var certificates: [Certificate]
    @Query private var availableDylibs: [AppFile]
    
    init(appFile: AppFile) {
        self.appFile = appFile
        let predicate = #Predicate<AppFile> { file in
            file.type.rawValue == FileType.dylib.rawValue
        }
        _availableDylibs = Query(filter: predicate, sort: \AppFile.name)
    }

    @State private var selectedCertificateID: UUID?
    @State private var activeTab = 0
    @State private var isSigning = false
    @State private var showSuccess = false
    @State private var signedIPAURL: URL?

    // Customization State
    @State private var newName = ""
    @State private var newID = ""
    @State private var newVersion = ""
    @State private var selectedDylibIDs: Set<UUID> = []
    @State private var showingFilePicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header Status
                    if isSigning {
                        VStack(spacing: 20) {
                            LottieView(name: "signing", loopMode: .loop).frame(width: 150, height: 150)
                            Text("Signing \(appFile.name)...").font(.headline).foregroundColor(XsignTheme.textPrimary)
                        }.padding()
                    } else if showSuccess {
                        VStack(spacing: 20) {
                            LottieView(name: "success", loopMode: .playOnce).frame(width: 150, height: 150)
                            Text("Signed Successfully!").font(.title3).fontWeight(.bold).foregroundColor(XsignTheme.success)
                            Button("Install Now") { startInstallation() }.buttonStyle(.borderedProminent).tint(XsignTheme.success)
                        }.padding()
                    } else {
                        // Multi-Tab Editor
                        Picker("Tab", selection: $activeTab) {
                            Text("Info").tag(0)
                            Text("Tweaks").tag(1)
                            Text("Cert").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding()

                        TabView(selection: $activeTab) {
                            // Tab 0: App Info Overrides
                            Form {
                                Section("App Metadata") {
                                    TextField("Display Name", text: $newName)
                                    TextField("Bundle Identifier", text: $newID)
                                    TextField("Short Version", text: $newVersion)
                                }
                            }
                            .scrollContentBackground(.hidden)
                            .tag(0)

                            // Tab 1: Tweaks & Injection
                            Form {
                                Section("Linked Dylibs") {
                                    if availableDylibs.isEmpty {
                                        Text("No dylibs imported yet").font(.caption).foregroundColor(.gray)
                                    } else {
                                        ForEach(availableDylibs) { dylib in
                                            Toggle(dylib.name, isOn: Binding(
                                                get: { selectedDylibIDs.contains(dylib.id) },
                                                set: { if $0 { selectedDylibIDs.insert(dylib.id) } else { selectedDylibIDs.remove(dylib.id) } }
                                            ))
                                        }
                                    }
                                    Button("Add from Filesystem...") { showingFilePicker = true }
                                        .font(.subheadline).foregroundColor(XsignTheme.primary)
                                }
                            }
                            .scrollContentBackground(.hidden)
                            .tag(1)

                            // Tab 2: Certificate Selection
                            Form {
                                Section("Signing Identity") {
                                    if certificates.isEmpty {
                                        NavigationLink("Import Certificate First") { ImportCertificateView() }
                                    } else {
                                        Picker("Select Certificate", selection: $selectedCertificateID) {
                                            Text("None Selected").tag(nil as UUID?)
                                            ForEach(certificates) { cert in
                                                Text(cert.name).tag(cert.id as UUID?)
                                            }
                                        }

                                        if let selectedID = selectedCertificateID, let cert = certificates.first(where: { $0.id == selectedID }) {
                                            InfoRow(label: "Common Name", value: cert.commonName)
                                            InfoRow(label: "Expires", value: cert.expiryDate.formatted(date: .abbreviated, time: .omitted))
                                        }
                                    }
                                }
                            }
                            .scrollContentBackground(.hidden)
                            .tag(2)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))

                        // Bottom Action
                        Button(action: executeSigning) {
                            Text("Sign & Install")
                                .fontWeight(.bold).frame(maxWidth: .infinity).padding()
                                .background(selectedCertificateID == nil ? Color.gray : XsignTheme.primary)
                                .foregroundColor(.white).cornerRadius(12)
                        }
                        .disabled(selectedCertificateID == nil)
                        .padding()
                    }
                }
            }
            .navigationTitle("Advanced Signing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.item]) { result in
                if let url = try? result.get().first {
                    Task { try? await FileService.shared.importFile(at: url) }
                }
            }
        }
        .onAppear {
            newName = appFile.name
            newID = appFile.bundleID ?? ""
            newVersion = appFile.version ?? ""
        }
    }

    private func executeSigning() {
        guard let cert = certificates.first(where: { $0.id == selectedCertificateID }) else { return }
        isSigning = true

        let options = SigningService.SigningOptions(
            bundleID: newID.isEmpty ? nil : newID,
            bundleName: newName.isEmpty ? nil : newName,
            bundleVersion: newVersion.isEmpty ? nil : newVersion,
            dylibPaths: availableDylibs.filter { selectedDylibIDs.contains($0.id) }.map { $0.filePath.path }
        )

        Task {
            do {
                let url = try await SigningService.shared.sign(appFile: appFile, certificate: cert, options: options)
                await MainActor.run {
                    self.signedIPAURL = url
                    self.isSigning = false
                    withAnimation { self.showSuccess = true }
                }
            } catch {
                await MainActor.run { self.isSigning = false }
            }
        }
    }

    private func startInstallation() {
        guard let url = signedIPAURL else { return }
        if let installURL = LocalServerService.shared.startServer(for: url, bundleID: newID, version: newVersion, name: newName) {
            UIApplication.shared.open(installURL)
        }
        dismiss()
    }
}
