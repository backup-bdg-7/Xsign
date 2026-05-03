import SwiftUI
import UniformTypeIdentifiers

// Define custom UTTypes for our file types
extension UTType {
    static let p12 = UTType(filenameExtension: "p12") ?? .data
    static let mobileprovision = UTType(filenameExtension: "mobileprovision") ?? .data
    static let ipa = UTType(filenameExtension: "ipa") ?? .data
    static let dylib = UTType(filenameExtension: "dylib") ?? .unixExecutable
    static let deb = UTType(filenameExtension: "deb") ?? .data
}

struct ImportCertificateView: View {
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var password = ""
    @State private var p12Data: Data?
    @State private var profileData: Data?
    @State private var showingP12Picker = false
    @State private var showingProfilePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Certificate Details") {
                    TextField("Name", text: $name)
                    SecureField("P12 Password (optional)", text: $password)
                }

                Section("Files") {
                    HStack {
                        Text(".p12 Certificate")
                        Spacer()
                        if p12Data != nil { 
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green) 
                        }
                        Button("Select") { showingP12Picker = true }
                    }

                    HStack {
                        Text("Provisioning Profile")
                        Spacer()
                        if profileData != nil { 
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green) 
                        }
                        Button("Select") { showingProfilePicker = true }
                    }
                }
            }
            .navigationTitle("Import Certificate")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCertificate() }
                        .disabled(name.isEmpty || p12Data == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(isPresented: $showingP12Picker, allowedContentTypes: [.p12]) { result in
                handleP12Import(result)
            }
            .fileImporter(isPresented: $showingProfilePicker, allowedContentTypes: [.mobileprovision]) { result in
                handleProfileImport(result)
            }
        }
    }
    
    private func handleP12Import(_ result: Result<URL, Error>) {
        if let url = try? result.get() {
            p12Data = try? Data(contentsOf: url)
        }
    }
    
    private func handleProfileImport(_ result: Result<URL, Error>) {
        if let url = try? result.get() {
            profileData = try? Data(contentsOf: url)
            if let data = profileData, 
               let profile = ProvisioningParser.shared.parse(data: data) {
                if name.isEmpty { name = profile.name }
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
        
        PersistenceService.shared.context.insert(newCert)
        PersistenceService.shared.save()
        dismiss()
    }
}
