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
                    // Export certificate action
                }) {
                    Label("Export Certificate", systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive, action: {
                    // Delete certificate action
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
        switch type {
        case .pushNotifications: return "bell.badge"
        case .icloud: return "icloud"
        case .appGroups: return "person.3"
        case .networkExtensions: return "network"
        case .applePay: return "creditcard.circle"
        case .backgroundModes: return "arrow.up.arrow.down.circle"
        case .dataProtection: return "lock.shield"
        case .fileAccess: return "folder"
        case .gameCenter: return "gamecontroller"
        case .healthKit: return "heart.text.square"
        case .homeKit: return "house"
        case .inAppPurchase: return "cart"
        case .keychainAccess: return "key"
        case .maps: return "map"
        case .personalVPN: return "vpn.bond"
        case .siri: return "mic.circle"
        case .wallet: return "wallet.bifold"
        case .wirelessAccessory: return "wifi"
        case .custom: return "gear"
        }
    }
    
    private func colorForCapability(_ type: CapabilityType) -> Color {
        switch type {
        case .pushNotifications: return .orange
        case .icloud: return .blue
        case .appGroups: return .green
        case .networkExtensions: return .purple
        case .applePay: return .black
        case .backgroundModes: return .gray
        case .dataProtection: return .red
        case .fileAccess: return .brown
        case .gameCenter: return .pink
        case .healthKit: return .red
        case .homeKit: return .orange
        case .inAppPurchase: return .blue
        case .keychainAccess: return .yellow
        case .maps: return .green
        case .personalVPN: return .purple
        case .siri: return .pink
        case .wallet: return .black
        case .wirelessAccessory: return .blue
        case .custom: return .gray
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
        case .applePay:
            return "Apple Pay allows your app to make secure payments using Apple Pay. Requires merchant ID setup and certification."
        case .backgroundModes:
            return "Background Modes allow your app to continue running in the background for specific tasks like audio playback, location updates, VoIP, or background fetch."
        case .dataProtection:
            return "Data Protection adds an additional layer of encryption to user data stored by your app. Files are encrypted using the user's passcode."
        case .fileAccess:
            return "File Access entitlements allow your app to access user files and folders. This includes read/write access to specific directories."
        case .gameCenter:
            return "Game Center enables leaderboards, achievements, and multiplayer functionality in your game. Users need an Apple ID to use Game Center."
        case .healthKit:
            return "HealthKit allows your app to read and write health and fitness data to the Health app. Requires privacy policy and user consent."
        case .homeKit:
            return "HomeKit allows your app to control HomeKit accessories and set up home automation scenes. Users need iOS devices with HomeKit setup."
        case .inAppPurchase:
            return "In-App Purchase allows your app to sell content, features, or subscriptions within the app. Requires App Store Connect setup."
        case .keychainAccess:
            return "Keychain Access allows your app to share credentials and sensitive data securely between your apps using the same keychain group."
        case .maps:
            return "Maps capability allows your app to integrate with Apple Maps for directions, display points of interest, and use map-based features."
        case .personalVPN:
            return "Personal VPN allows your app to create and manage VPN configurations on the device. Requires special entitlements from Apple."
        case .siri:
            return "Siri allows your app to integrate with Siri for voice commands and shortcuts. Users can control your app with voice commands."
        case .wallet:
            return "Wallet allows your app to add passes, tickets, boarding passes, and loyalty cards to Apple Wallet. Requires pass certificate."
        case .wirelessAccessory:
            return "Wireless Accessory Configuration allows your app to configure Wi-Fi networks and Bluetooth accessories. Used for IoT devices."
        case .custom:
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
