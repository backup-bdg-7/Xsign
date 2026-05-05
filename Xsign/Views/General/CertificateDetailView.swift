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
                Button {
                    // Export certificate action
                } label: {
                    Label("Export Certificate", systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive) {
                    // Delete certificate action
                } label: {
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
        switch type {
        case .pushNotifications: return "bell.badge"
        case .icloud: return "icloud"
        case .appGroups: return "person.3"
        case .networkExtensions: return "network"
        case .other: return "gear"
        }
    }
    
    private func colorForCapability(_ type: CapabilityType) -> Color {
        switch type {
        case .pushNotifications: return .orange
        case .icloud: return .blue
        case .appGroups: return .green
        case .networkExtensions: return .purple
        case .other: return .gray
        }
    }
}

struct EntitlementDetailView: View {
    let entitlement: Entitlement
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Entitlement Details") {
                    InfoRow(label: "Name", value: entitlement.name)
                    InfoRow(label: "Capability Type", value: entitlement.capabilityType.rawValue)
                    InfoRow(label: "Platform", value: entitlement.platform)
                    InfoRow(label: "Required", value: entitlement.isRequired ? "Yes" : "No")
                }
                
                Section("Description") {
                    Text(entitlement.entitlementDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Section("What does this mean?") {
                    Text(descriptionForEntitlement(entitlement))
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(entitlement.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func descriptionForEntitlement(_ entitlement: Entitlement) -> String {
        switch entitlement.capabilityType {
        case .pushNotifications:
            return "Push Notifications allow your app to receive notifications from a server even when the app is not running. This requires setting up push notification certificates in your Apple Developer account."
        case .icloud:
            return "iCloud capability allows your app to store data in iCloud, sync across devices, and use CloudKit for database storage. Requires iCloud containers setup."
        case .appGroups:
            return "App Groups allow multiple apps from the same developer to share data (UserDefaults, files) between them. Useful for app suites or shared extensions."
        case .networkExtensions:
            return "Network Extensions allow your app to perform custom network processing, create VPN configurations, or implement content filtering. Requires special entitlements."
        case .other:
            return entitlement.entitlementDescription.isEmpty ? "This is a custom entitlement. Check Apple's documentation for more details." : entitlement.entitlementDescription
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}
