import SwiftUI
import SwiftData

struct SignModalView: View {
    let appFile: AppFile
    @Environment(\.dismiss) var dismiss
    @Query(sort: \Certificate.name) private var certificates: [Certificate]
    @State private var selectedCertificateID: UUID?
    @State private var isSigning = false
    @State private var showSuccess = false
    @State private var signedIPAURL: URL?
    @State private var newBundleID = ""
    @State private var newBundleName = ""
    @State private var modifyEnabled = false
    @Query(filter: #Predicate<AppFile> { $0.type == .dylib }) private var availableDylibs: [AppFile]
    @State private var selectedDylibs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()
                if isSigning {
                    VStack { LottieView(name: "signing", loopMode: .loop).frame(width: 150, height: 150); Text("Signing...") }
                } else if showSuccess {
                    VStack { Image(systemName: "checkmark.circle.fill").font(.system(size: 80)).foregroundColor(.green); Button("Install") { startInstall() }.buttonStyle(.borderedProminent) }
                } else {
                    Form {
                        Section("Cert") {
                            Picker("Select", selection: $selectedCertificateID) {
                                Text("None").tag(nil as UUID?)
                                ForEach(certificates) { Text($0.name).tag($0.id as UUID?) }
                            }
                        }
                        Section(header: Toggle("Modify", isOn: $modifyEnabled)) {
                            if modifyEnabled { TextField("Name", text: $newBundleName); TextField("ID", text: $newBundleID) }
                        }
                        Section("Inject") { ForEach(availableDylibs) { dylib in Toggle(dylib.name, isOn: Binding(get: { selectedDylibs.contains(dylib.id) }, set: { if $0 { selectedDylibs.insert(dylib.id) } else { selectedDylibs.remove(dylib.id) } })) } }
                        Button("Sign") { startSign() }.disabled(selectedCertificateID == nil)
                    }
                }
            }.navigationTitle("Sign").toolbar { Button("Close") { dismiss() } }
        }.onAppear { newBundleID = appFile.bundleID ?? ""; newBundleName = appFile.name }
    }
    func startSign() {
        guard let cert = certificates.first(where: { $0.id == selectedCertificateID }) else { return }
        isSigning = true
        let dylibs = availableDylibs.filter { selectedDylibs.contains($0.id) }.map { $0.filePath.path }
        Task {
            let options = SigningService.SigningOptions(bundleID: modifyEnabled ? newBundleID : nil, bundleName: modifyEnabled ? newBundleName : nil, dylibPaths: dylibs)
            if let url = try? await SigningService.shared.sign(appFile: appFile, certificate: cert, options: options) {
                await MainActor.run { self.signedIPAURL = url; self.isSigning = false; self.showSuccess = true }
            } else { await MainActor.run { self.isSigning = false } }
        }
    }
    func startInstall() {
        guard let url = signedIPAURL else { return }
        Task {
            if let iUrl = try? await LocalServerService.shared.startServer(for: url, bundleID: newBundleID, version: "1.0", name: newBundleName) { UIApplication.shared.open(iUrl) }
            dismiss()
        }
    }
}
