import SwiftUI
import SwiftData

struct SignModalView: View {
    let appFile: AppFile
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Certificate.name) private var certificates: [Certificate]
    @State private var availableDylibs: [AppFile] = []
    
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
                
                if isSigning {
                    signingInProgressView
                } else if showSuccess {
                    successView
                } else {
                    mainEditorView
                }
            }
            .navigationTitle("Advanced Signing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.item]) { result in
                handleFileImport(result)
            }
            .onAppear {
                loadDylibs()
                newName = appFile.name
                newID = appFile.bundleID ?? ""
                newVersion = appFile.version ?? ""
            }
        }
    }
    
    private var signingInProgressView: some View {
        VStack(spacing: 20) {
            LottieView(name: "signing", loopMode: .loop)
                .frame(width: 150, height: 150)
            Text("Signing \(appFile.name)...")
                .font(.headline)
                .foregroundColor(XsignTheme.textPrimary)
        }
        .padding()
    }
    
    private var successView: some View {
        VStack(spacing: 20) {
            LottieView(name: "success", loopMode: .playOnce)
                .frame(width: 150, height: 150)
            Text("Signed Successfully!")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(XsignTheme.success)
            Button("Install Now") { startInstallation() }
                .buttonStyle(.borderedProminent)
                .tint(XsignTheme.success)
        }
        .padding()
    }
    
    private var mainEditorView: some View {
        VStack(spacing: 0) {
            Picker("Tab", selection: $activeTab) {
                Text("Info").tag(0)
                Text("Tweaks").tag(1)
                Text("Cert").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            TabView(selection: $activeTab) {
                appInfoTab.tag(0)
                tweaksTab.tag(1)
                certificateTab.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            Button(action: executeSigning) {
                Text("Sign & Install")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedCertificateID == nil ? Color.gray : XsignTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(selectedCertificateID == nil)
            .padding()
        }
    }
    
    private var appInfoTab: some View {
        Form {
            Section("App Metadata") {
                TextField("Display Name", text: $newName)
                TextField("Bundle Identifier", text: $newID)
                TextField("Short Version", text: $newVersion)
            }
        }
        .scrollContentBackground(.hidden)
    }
    
    private var tweaksTab: some View {
        Form {
            Section("Linked Dylibs") {
                if availableDylibs.isEmpty {
                    Text("No dylibs imported yet")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    ForEach(availableDylibs) { dylib in
                        Toggle(dylib.name, isOn: Binding(
                            get: { selectedDylibIDs.contains(dylib.id) },
                            set: { 
                                if $0 { selectedDylibIDs.insert(dylib.id) } 
                                else { selectedDylibIDs.remove(dylib.id) } 
                            }
                        ))
                    }
                }
                Button("Add from Filesystem...") { showingFilePicker = true }
                    .font(.subheadline)
                    .foregroundColor(XsignTheme.primary)
            }
        }
        .scrollContentBackground(.hidden)
    }
    
    private var certificateTab: some View {
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
                    
                    if let selectedID = selectedCertificateID, 
                       let cert = certificates.first(where: { $0.id == selectedID }) {
                        InfoRow(label: "Common Name", value: cert.commonName)
                        InfoRow(label: "Expires", value: cert.expiryDate.formatted(date: .abbreviated, time: .omitted))
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
    
    private func loadDylibs() {
        let dylibRawValue = FileType.dylib.rawValue
        let predicate = #Predicate<AppFile> { file in
            file.type.rawValue == dylibRawValue
        }
        let descriptor = FetchDescriptor<AppFile>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        availableDylibs = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func handleFileImport(_ result: Result<URL, Error>) {
        if let url = try? result.get() {
            Task { try? await FileService.shared.importFile(at: url) }
        }
    }
    
    private func executeSigning() {
        guard let cert = certificates.first(where: { $0.id == selectedCertificateID }) else { return }
        isSigning = true
        
        // Create SigningOptions from the model
        let options = SigningOptions(
            ppqProtection: false, // User can set this in Settings
            appAppearance: .default,
            minimumAppRequirement: .default,
            signingOption: .default,
            fileSharing: false,
            itunesFileSharing: false,
            proMotion: false,
            gameMode: false,
            ipadFullscreen: false,
            removeURLScheme: false,
            removeProvisioning: false,
            changeLanguageFilesForCustomDisplayName: false,
            post_installAppAfterSigned: false,
            post_deleteAppAfterSigned: false,
            experiment_replaceSubstrateWithEllekit: false,
            experiment_supportLiquidGlass: false,
            customBundleID: newID.isEmpty ? nil : newID,
            customDisplayName: newName.isEmpty ? nil : newName,
            customVersion: newVersion.isEmpty ? nil : newVersion,
            customBuildVersion: nil,
            customAppIcon: nil,
            entitlements: nil,
            dylibsToInject: selectedDylibIDs.compactMap { id in
                availableDylibs.first { $0.id == id }?.filePath
            }
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
