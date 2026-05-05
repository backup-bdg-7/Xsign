import SwiftUI
import SwiftData

struct EntitlementsListView: View {
    let title: String
    let entitlements: [String: Any]
    @State private var searchText = ""
    
    var filteredKeys: [String] {
        if searchText.isEmpty {
            return entitlements.keys.sorted()
        } else {
            return entitlements.keys.filter { key in
                key.localizedCaseInsensitiveContains(searchText) ||
                "\(entitlements[key] ?? "")".localizedCaseInsensitiveContains(searchText)
            }.sorted()
        }
    }
    
    var body: some View {
        ZStack {
            XsignTheme.background.ignoresSafeArea()
            
            if entitlements.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No entitlements found")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section(header: Text("\(entitlements.count) Entitlements")) {
                        ForEach(filteredKeys, id: \.self) { key in
                            EntitlementRowView(key: key, value: entitlements[key])
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search entitlements...")
    }
}

struct EntitlementRowView: View {
    let key: String
    let value: Any?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(key)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(XsignTheme.primary)
            
            Text(formatValue(value))
                .font(.caption2)
                .foregroundColor(XsignTheme.textSecondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
    
    private func formatValue(_ value: Any?) -> String {
        guard let value = value else { return "nil" }
        
        if let boolValue = value as? Bool {
            return boolValue ? "true" : "false"
        } else if let stringValue = value as? String {
            return stringValue
        } else if let arrayValue = value as? [Any] {
            return "[\(arrayValue.count) items]"
        } else if let dictValue = value as? [String: Any] {
            return "{\(dictValue.count) keys}"
        } else if let numberValue = value as? NSNumber {
            return "\(numberValue)"
        } else {
            return "\(value)"
        }
    }
}

// View for displaying entitlements of a certificate
struct CertificateEntitlementsView: View {
    let certificate: Certificate
    @State private var entitlements: [String: Any] = [:]
    
    var body: some View {
        ZStack {
            XsignTheme.background.ignoresSafeArea()
            
            EntitlementsListView(
                title: "\(certificate.name) Entitlements",
                entitlements: entitlements
            )
        }
        .onAppear {
            loadEntitlements()
        }
    }
    
    private func loadEntitlements() {
        guard let certData = certificate.certificateData else { return }
        
        // Extract entitlements from the certificate's provisioning profile
        if let profileData = extractProvisioningProfile(from: certData),
           let extracted = EntitlementManager.shared.extractEntitlements(from: profileData) {
            entitlements = extracted
        }
    }
    
    private func extractProvisioningProfile(from certData: Data) -> Data? {
        // This is a simplified version - in reality, need to parse the certificate
        // For now, return nil
        return nil
    }
}

#Preview {
    // Mock entitlements for preview
    let mockEntitlements: [String: Any] = [
        "application-identifier": "com.example.app",
        "get-task-allow": true,
        "com.apple.developer.team-identifier": "TEAMID",
        "com.apple.security.application-groups": ["group.com.example.app"]
    ]
    
    EntitlementsListView(
        title: "App Entitlements",
        entitlements: mockEntitlements
    )
}
