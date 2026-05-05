import SwiftUI
import UniformTypeIdentifiers

struct ImportCertificateView: View {
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var password = ""
    @State private var p12URL: URL?
    @State private var provisionURL: URL?
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
                        if p12URL != nil { 
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green) 
                        }
                        Button(p12URL == nil ? "Select" : "Change") { 
                            showingP12Picker = true 
                        }
                    }

                    HStack {
                        Text("Provisioning Profile")
                        Spacer()
                        if provisionURL != nil { 
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green) 
                        }
                        Button(provisionURL == nil ? "Select" : "Change") { 
                            showingProfilePicker = true 
                        }
                    }
                }
            }
            .navigationTitle("Import Certificate")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCertificate() }
                        .disabled(name.isEmpty || p12URL == nil || provisionURL == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingP12Picker) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.p12],
                    onDocumentsPicked: { urls in
                        guard let selectedFileURL = urls.first else { return }
                        p12URL = selectedFileURL
                        // Try to parse provisioning profile to get name if not set
                        if name.isEmpty {
                            // Will set name after both files are selected
                        }
                    }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingProfilePicker) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.mobileprovision],
                    onDocumentsPicked: { urls in
                        guard let selectedFileURL = urls.first else { return }
                        provisionURL = selectedFileURL
                        // Try to parse provisioning profile to get name if not set
                        if name.isEmpty {
                            do {
                                let data = try Data(contentsOf: selectedFileURL)
                                let profile = try ProvisioningParser.shared.parse(provisioningProfile: data)
                                name = profile.appID ?? "Profile"
                            } catch {
                                print("Failed to parse provisioning profile: \(error)")
                            }
                        }
                    }
                )
                .ignoresSafeArea()
            }
        }
    }
    
    private func saveCertificate() {
        guard let p12URL = p12URL,
              let provisionURL = provisionURL else { return }
        
        do {
            let p12Data = try Data(contentsOf: p12URL)
            let provisionData = try Data(contentsOf: provisionURL)
            
            // Verify the certificate can be used for signing
            // (In a real implementation, you'd verify the p12 password here)
            
            let newCert = Certificate(
                name: name,
                p12Data: p12Data,
                provisioningProfileData: provisionData,
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
        } catch {
            print("Failed to save certificate: \(error)")
        }
    }
}
