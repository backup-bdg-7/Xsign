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
        // Core Certificate Entitlements
        case .applicationIdentifier: return "signature"
        case .keychainAccessGroups: return "key.2"
        case .getTaskAllow: return "hammer"
        case .teamIdentifier: return "person.3"
        
        // App Services
        case .pushNotifications: return "bell.badge"
        case .applePay: return "creditcard.circle"
        case .appGroups: return "person.3"
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
        
        // Networking
        case .networkExtensions: return "network"
        case .hotspotHelper: return "personalhotspot"
        case .multipath: return "antenna.radiowaves.left.and.right"
        case .vpnConfiguration: return "lock.shield"
        
        // Hardware
        case .nfc: return "radiowaves.right"
        case .camera: return "camera"
        case .microphone: return "mic"
        case .bluetooth: return "bluetooth"
        case .externalAccessory: return "cable.connector"
        
        // Security
        case .sharedPassword: return "person.crop.circle.badge.checkmark"
        case .associatedDomains: return "link"
        
        // Media
        case .mediaLibrary: return "photo.on.rectangle"
        case .musicRecognition: return "music.note"
        case .photoLibrary: return "photo"
        case .videoSubscriber: return "tv"
        
        // Communication
        case .callKit: return "phone"
        case .messageFilter: return "message"
        case .contacts: return "person.2"
        
        // iCloud
        case .icloud: return "icloud"
        case .ubiquityContainer: return "internaldrive"
        case .ubiquityKVStore: return "key"
        }
    }
    
    private func colorForCapability(_ type: CapabilityType) -> Color {
        switch type {
        // Core Certificate Entitlements
        case .applicationIdentifier: return .blue
        case .keychainAccessGroups: return .yellow
        case .getTaskAllow: return .gray
        case .teamIdentifier: return .green
        
        // App Services
        case .pushNotifications: return .orange
        case .applePay: return .black
        case .appGroups: return .green
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
        
        // Networking
        case .networkExtensions: return .purple
        case .hotspotHelper: return .green
        case .multipath: return .blue
        case .vpnConfiguration: return .red
        
        // Hardware
        case .nfc: return .blue
        case .camera: return .gray
        case .microphone: return .pink
        case .bluetooth: return .blue
        case .externalAccessory: return .gray
        
        // Security
        case .sharedPassword: return .green
        case .associatedDomains: return .blue
        
        // Media
        case .mediaLibrary: return .purple
        case .musicRecognition: return .orange
        case .photoLibrary: return .blue
        case .videoSubscriber: return .red
        
        // Communication
        case .callKit: return .green
        case .messageFilter: return .orange
        case .contacts: return .blue
        
        // iCloud
        case .icloud: return .blue
        case .ubiquityContainer: return .purple
        case .ubiquityKVStore: return .yellow
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
        // Core Certificate Entitlements
        case .applicationIdentifier:
            return "Application Identifier (App ID) is the unique identifier for your app (e.g., ABCDE12345.com.example.app). This is the primary entitlement that ties your app to your developer account."
        case .keychainAccessGroups:
            return "Keychain Access Groups allow sharing keychain items between apps from the same developer. More specific than general keychain access. Format: <team-id>.<group-name>"
        case .getTaskAllow:
            return "Get Task Allow is a debugging entitlement that allows attaching a debugger to the app. Should be set to 'false' for production apps distributed on the App Store."
        case .teamIdentifier:
            return "Team Identifier is your Apple Developer Team ID (e.g., ABCDE12345). This entitlement identifies which development team the app belongs to."
        
        // App Services
        case .pushNotifications:
            return "Push Notifications allow your app to receive notifications from a server even when the app is not running. This requires setting up push notification certificates in your Apple Developer account."
        case .applePay:
            return "Apple Pay allows your app to make secure payments using Apple Pay. Requires merchant ID setup and certification."
        case .appGroups:
            return "App Groups allow multiple apps from the same developer to share data (UserDefaults, files) between them. Useful for app suites or shared extensions."
        case .backgroundModes:
            return "Background Modes allow your app to continue running in the background for specific tasks like audio playback, location updates, VoIP, or background fetch."
        case .dataProtection:
            return "Data Protection adds an additional layer of encryption to user data stored by your app. Files are encrypted using the user's passcode. Levels: Complete, UnlessOpen, UntilFirstAuth."
        case .fileAccess:
            return "File Access entitlements allow your app to access user files and folders. This includes read/write access to specific directories like Documents, Library, etc."
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
        
        // Networking
        case .networkExtensions:
            return "Network Extensions allow your app to perform custom network processing, create VPN configurations, or implement content filtering. Requires special entitlements."
        case .hotspotHelper:
            return "Hotspot Helper allows your app to participate in Wi-Fi hotspot authentication. The app can help users connect to hotspots and handle authentication."
        case .multipath:
            return "Multipath allows your app to use multiple network paths simultaneously for improved performance and reliability. Requires special entitlement."
        case .vpnConfiguration:
            return "VPN Configuration allows your app to create and manage VPN configurations. Similar to Personal VPN but with different implementation approach."
        
        // Hardware
        case .nfc:
            return "NFC (Near Field Communication) allows your app to read NFC tags. Used for contactless payments, access cards, and smart home devices. Requires NFC capability."
        case .camera:
            return "Camera entitlement allows your app to access the device's camera for taking photos and videos. Requires user permission at runtime."
        case .microphone:
            return "Microphone entitlement allows your app to record audio. Requires user permission at runtime. Used for voice recording, calls, etc."
        case .bluetooth:
            return "Bluetooth entitlement allows your app to communicate with Bluetooth peripherals. Requires user permission for BLE devices."
        case .externalAccessory:
            return "External Accessory allows your app to communicate with hardware accessories connected via the Apple Lightning or USB-C port. Requires MFi program."
        
        // Security
        case .sharedPassword:
            return "Shared Password entitlement allows your app to share passwords with other apps using the same App ID prefix. Used for SSO flows."
        case .associatedDomains:
            return "Associated Domains allow your app to link with your website for Handoff, Universal Links, and Shared Web Credentials. Requires domain verification."
        
        // Media
        case .mediaLibrary:
            return "Media Library allows your app to access the user's media library (music, videos, podcasts). Requires user permission."
        case .musicRecognition:
            return "Music Recognition (Shazam) allows your app to identify music playing around the device. Requires Shazam entitlement from Apple."
        case .photoLibrary:
            return "Photo Library allows your app to access the user's photo library to read and write photos and videos. Requires user permission."
        case .videoSubscriber:
            return "Video Subscriber entitlement allows your app to authenticate users for streaming video services. Used by TV providers."
        
        // Communication
        case .callKit:
            return "CallKit allows your app to integrate with the iOS calling interface. Used for VoIP apps to show incoming calls like native calls."
        case .messageFilter:
            return "Message Filter allows your app to filter SMS and MMS messages. The app can classify messages as spam or organize them."
        case .contacts:
            return "Contacts entitlement allows your app to access the user's contacts. Requires user permission. Used for social and communication apps."
        
        // iCloud
        case .icloud:
            return "iCloud capability allows your app to store data in iCloud, sync across devices, and use CloudKit for database storage. Requires iCloud containers setup."
        case .ubiquityContainer:
            return "Ubiquity Container (iCloud) specifies which iCloud container your app can access. Format: <team-id>.<container-name>. Used for CloudKit and iCloud Drive."
        case .ubiquityKVStore:
            return "Ubiquity Key-Value Store (iCloud) allows your app to sync key-value data across devices using iCloud KV Store. Similar to UserDefaults but synced."
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
