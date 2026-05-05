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
                if let nickname = certificate.nickname, !nickname.isEmpty {
                    InfoRow(label: "Nickname", value: nickname)
                }
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
                    // Export certificate - save the .p12 file to documents and share
                    do {
                        let p12Data = try certificate.decryptedP12Data()
                        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let fileURL = documentsURL.appendingPathComponent("\(certificate.name).p12")
                        try p12Data.write(to: fileURL)
                        
                        // Share the file using UIActivityViewController
                        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootVC = windowScene.keyWindow?.rootViewController {
                            rootVC.present(activityVC, animated: true)
                        }
                        
                        PersistenceService.shared.log(level: .info, category: "Certificate", message: "Exported certificate: \(certificate.name)")
                    } catch {
                        PersistenceService.shared.log(level: .error, category: "Certificate", message: "Failed to export certificate", details: error.localizedDescription)
                    }
                }) {
                    Label("Export Certificate", systemImage: "square.and.arrow.up")
                }
                
                if let entitlements = certificate.entitlements, !entitlements.isEmpty {
                    NavigationLink(destination: EntitlementsListView(entitlements: entitlements)) {
                        Label("View Entitlements", systemImage: "list.bullet")
                    }
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

struct EntitlementRow: View {
    let entitlement: Entitlement
    
    var body: some View {
        HStack {
            Image(systemName: iconForCapability(entitlement.capabilityType))
                .foregroundColor(colorForCapability(entitlement.capabilityType))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entitlement.name)
                    .font(.headline)
                Text(entitlement.capabilityType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if entitlement.isRequired {
                Text("Required")
                    .font(.caption2)
                    .padding(4)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(4)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func iconForCapability(_ type: CapabilityType) -> String {
        // Return appropriate icon for each capability type
        return "questionmark"
    }
    
    private func colorForCapability(_ type: CapabilityType) -> Color {
        return .blue
    }
}

struct EntitlementDetailView: View {
    let entitlement: Entitlement
    
    var body: some View {
        List {
            Section("Details") {
                InfoRow(label: "Name", value: entitlement.name)
                InfoRow(label: "Type", value: entitlement.capabilityType.rawValue)
                InfoRow(label: "Required", value: entitlement.isRequired ? "Yes" : "No")
            }
            
            Section("Description") {
                Text(entitlement.capabilityType.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(entitlement.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EntitlementsListView: View {
    let entitlements: [Entitlement]
    @State private var selectedEntitlement: Entitlement?
    @State private var showingDetail = false
    
    var body: some View {
        List {
            ForEach(entitlements) { entitlement in
                EntitlementRow(entitlement: entitlement)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEntitlement = entitlement
                        showingDetail = true
                    }
            }
        }
        .navigationTitle("Entitlements")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDetail) {
            if let entitlement = selectedEntitlement {
                EntitlementDetailView(entitlement: entitlement)
            }
        }
    }
}
