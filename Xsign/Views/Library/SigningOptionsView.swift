import SwiftUI

// MARK: - SigningOptionsView
// Based on Feather's SigningOptionsView
struct SigningOptionsView: View {
    @State private var options = OptionsManager.shared.options
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            // Protection section
            Section(header: Text("Protection")) {
                Toggle(isOn: $options.ppqProtection) {
                    Label("PPQ Protection", systemImage: "shield")
                }
                .tint(.blue)
                
                if options.ppqProtection {
                    Text("Enabling PPQ protection will append a random string to the bundle identifier of signed apps. This helps prevent your Apple ID from being flagged by Apple.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // General section
            Section(header: Text("General")) {
                Picker(selection: $options.appAppearance, label: Label("Appearance", systemImage: "paintpalette")) {
                    ForEach(AppAppearance.allCases, id: \.self) { value in
                        Text(value.localizedDescription).tag(value)
                    }
                }
                
                Picker(selection: $options.minimumAppRequirement, label: Label("Minimum Requirement", systemImage: "ruler")) {
                    ForEach(MinimumAppRequirement.allCases, id: \.self) { value in
                        Text(value.localizedDescription).tag(value)
                    }
                }
            }
            
            // Signing Type
            Section(header: Text("Signing Type")) {
                Picker(selection: $options.signingOption, label: Label("Signing Type", systemImage: "signature")) {
                    ForEach(SigningOption.allCases, id: \.self) { value in
                        Text(value.localizedDescription).tag(value)
                    }
                }
            }
            
            // App Features
            Section(header: Text("App Features")) {
                Toggle(isOn: $options.fileSharing) {
                    Label("File Sharing", systemImage: "folder.badge.person.crop")
                }
                .tint(.blue)
                Text("Enable file sharing via Files app. Allows users to access app's documents folder.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle(isOn: $options.itunesFileSharing) {
                    Label("iTunes File Sharing", systemImage: "music.note.list")
                }
                .tint(.blue)
                Text("Enable iTunes file sharing for the app. Allows accessing files via iTunes/Finder.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle(isOn: $options.proMotion) {
                    Label("Pro Motion", systemImage: "speedometer")
                }
                .tint(.blue)
                Text("Enable ProMotion high refresh rate support (120Hz) on supported devices.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle(isOn: $options.gameMode) {
                    Label("Game Mode", systemImage: "gamecontroller")
                }
                .tint(.blue)
                Text("Enable Game Mode optimizations for better gaming performance.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle(isOn: $options.ipadFullscreen) {
                    Label("iPad Fullscreen", systemImage: "ipad.landscape")
                }
                .tint(.blue)
                Text("Allow the app to run in fullscreen mode on iPad.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Removal
            Section(header: Text("Removal")) {
                Toggle(isOn: $options.removeURLScheme) {
                    Label("Remove URL Scheme", systemImage: "ellipsis.curlybraces")
                }
                .tint(.blue)
                
                Toggle(isOn: $options.removeProvisioning) {
                    Label("Remove Provisioning", systemImage: "doc.badge.gearshape")
                }
                .tint(.blue)
                
                if options.removeProvisioning {
                    Text("Removing the provisioning file will exclude the mobileprovision file from being embedded inside the application when signing, to help prevent any detection.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Language/Display
            Section {
                Toggle(isOn: $options.changeLanguageFilesForCustomDisplayName) {
                    Label("Force Localize", systemImage: "character.bubble")
                }
                .tint(.blue)
                
                if options.changeLanguageFilesForCustomDisplayName {
                    Text("By default, localized titles for the app won't be changed, however this option overrides it.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Post Signing
            Section(header: Text("Post Signing")) {
                Toggle(isOn: $options.post_installAppAfterSigned) {
                    Label("Install After Signing", systemImage: "arrow.down.circle")
                }
                .tint(.blue)
                Text("Automatically install the app after signing is complete.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle(isOn: $options.post_deleteAppAfterSigned) {
                    Label("Delete After Signing", systemImage: "trash")
                }
                .tint(.blue)
                
                if options.post_deleteAppAfterSigned {
                    Text("This will delete your imported application after signing, to save on unused space.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Experiments
            Section(header: Text("Experiments")) {
                Toggle(isOn: $options.experiment_replaceSubstrateWithEllekit) {
                    Label("Replace Substrate with ElleKit", systemImage: "pencil")
                }
                .tint(.blue)
                Text("Replace Cydia Substrate with ElleKit for tweak injection.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle(isOn: $options.experiment_supportLiquidGlass) {
                    Label("Enable Liquid Glass", systemImage: "26.circle")
                }
                .tint(.blue)
                
                if options.experiment_supportLiquidGlass {
                    Text("This option force converts apps to try to use the new liquid glass redesign iOS 26 introduced, this may not work for all applications due to differing frameworks.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Signing Options")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    OptionsManager.shared.options = options
                    dismiss()
                }
            }
        }
    }
}
