import SwiftUI
import SwiftData

struct CertificateDetailView: View {
    let certificate: Certificate
    @State private var selectedEntitlement: Entitlement?
    @State private var showingEntitlementDetail = false
    
    var body: some View {
        List {
            // Certificate Info Section
            Section("Certificate Information") {
                InfoRow(label: "Name", value: certificate.name)
                InfoRow(label: "Common Name", value: certificate.commonName)
                InfoRow(label: "Type", value: certificate.type.rawValue.capitalized)
                InfoRow(label: "Fingerprint", value: certificate.fingerprint)
                InfoRow(label: "Expiry Date", value: certificate.expiryDate.formatted(date: .abbreviated, time: .shortened))
                InfoRow(label: "Can Sign", value: certificate.canSign ? "Yes" : "No")
            }
            
            // Entitlements Section
            if let entitlements = certificate.entitlements, !entitlements.isEmpty {
                Section("Entitlements (\(entitlements.count))") {
                    ForEach(entitlements) { entitlement in
                        EntitlementRow(entitlement: entitlement)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEntitlement = entitlement
                                showingEntitlementDetail = true
                            }
                    }
                }
            }
            
            // Actions Section
            Section {
                Button(action: {
                    // Export certificate - export the .p12 file
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.p12]
                    panel.nameFieldStringValue = "\(certificate.name).p12"
                    panel.begin { response in
                        if response == .OK, let url = panel.url {
                            do {
                                let p12Data = try certificate.decryptedP12Data()
                                try p12Data.write(to: url)
                                PersistenceService.shared.log(level: .info, category: "Certificate", message: "Exported certificate: \(certificate.name)")
                            } catch {
                                PersistenceService.shared.log(level: .error, category: "Certificate", message: "Failed to export certificate", details: error.localizedDescription)
                            }
                        }
                    }
                }) {
                    Label("Export Certificate", systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive, action: {
                    // Delete certificate action
                    let context = PersistenceService.shared.context
                    context.delete(certificate)
                    PersistenceService.shared.save()
                    PersistenceService.shared.log(level: .info, category: "Certificate", message: "Deleted certificate: \(certificate.name)")
                }) {
                    Label("Delete Certificate", systemImage: "trash")
                }
            }
        }
        .navigationTitle(certificate.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEntitlementDetail) {
            if let entitlement = selectedEntitlement {
                EntitlementDetailView(entitlement: entitlement)
            }
        }
    }
}
