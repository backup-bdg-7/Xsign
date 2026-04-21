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

    // Modification Overrides
    @State private var newBundleID = ""
    @State private var newVersion = ""
    @State private var newBuild = ""
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
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: XsignTheme.primary))
                                .scaleEffect(2)
                            Text("Signing and Injecting...")
                                .foregroundColor(XsignTheme.textPrimary)
                        }
                    } else if showSuccess {
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(XsignTheme.success)
                            Text("Ready to Install!")
                                .font(.title2).fontWeight(.bold).foregroundColor(XsignTheme.textPrimary)
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
                                    TextField("Bundle ID", text: $newBundleID)
                                    TextField("Version", text: $newVersion)
                                    TextField("Build", text: $newBuild)
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
                            Text("Sign App")
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
            }
            .navigationTitle("Sign IPA")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
        .onAppear {
            newBundleID = appFile.bundleID ?? ""
            newVersion = appFile.version ?? ""
            newBuild = appFile.build ?? ""
        }
    }

    private func startSigning() {
        guard let certID = selectedCertificateID,
              let certificate = certificates.first(where: { $0.id == certID }) else { return }

        isSigning = true

        Task {
            do {
                _ = try await SigningService.shared.sign(appFile: appFile, certificate: certificate)

                withAnimation {
                    isSigning = false
                    showSuccess = true
                }
            } catch {
                isSigning = false
            }
        }
    }

    private func startInstallation() {
        if let url = LocalServerService.shared.startServer(for: appFile) {
            UIApplication.shared.open(url)
        }
        dismiss()
    }
}

struct ImportCertificateView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var name = ""
    @State private var password = ""
    @State private var p12Data: Data?
    @State private var profileData: Data?
    @State private var showingP12Picker = false
    @State private var showingProfilePicker = false

    var body: some View {
        Form {
            Section("Certificate Details") {
                TextField("Name", text: $name)
                SecureField("P12 Password", text: $password)
            }

            Section("Files") {
                HStack {
                    Text(".p12 File")
                    Spacer()
                    if p12Data != nil {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    }
                    Button("Select") { showingP12Picker = true }
                }

                HStack {
                    Text(".mobileprovision")
                    Spacer()
                    if profileData != nil {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    }
                    Button("Select") { showingProfilePicker = true }
                }
            }
        }
        .navigationTitle("Import Certificate")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveCertificate()
                }
                .disabled(name.isEmpty || p12Data == nil)
            }
        }
        .fileImporter(isPresented: $showingP12Picker, allowedContentTypes: [.item]) { result in
            if let url = try? result.get().first {
                p12Data = try? Data(contentsOf: url)
            }
        }
        .fileImporter(isPresented: $showingProfilePicker, allowedContentTypes: [.item]) { result in
            if let url = try? result.get().first {
                profileData = try? Data(contentsOf: url)
                if let data = profileData, let profile = ProvisioningParser.shared.parse(data: data) {
                    if name.isEmpty { name = profile.name }
                }
            }
        }
    }

    private func saveCertificate() {
        guard let p12 = p12Data else { return }

        let newCert = Certificate(
            name: name,
            p12Data: p12,
            provisioningProfileData: profileData,
            password: password.isEmpty ? nil : password,
            type: .distribution,
            expiryDate: Date().addingTimeInterval(365*24*60*60),
            commonName: name,
            fingerprint: UUID().uuidString,
            canSign: true
        )

        modelContext.insert(newCert)
        try? modelContext.save()
        dismiss()
    }
}
