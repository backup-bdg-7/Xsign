import SwiftUI

struct AppDetailView: View {
    let appFile: AppFile
    @State private var showingSignModal = false
    @State private var extractedDylibs: [String] = []
    @State private var entitlements: [String: Any] = [:]
    
    var body: some View {
        ZStack {
            XsignTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    HStack(spacing: 20) {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(XsignTheme.surface)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "app.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(XsignTheme.primary)
                            )
                        VStack(alignment: .leading) {
                            Text(appFile.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(XsignTheme.textPrimary)
                            Text(appFile.bundleID ?? "No Bundle ID")
                                .font(.caption)
                                .foregroundColor(XsignTheme.textSecondary)
                            StatusBadge(status: appFile.signatureStatus)
                                .padding(.top, 4)
                        }
                        Spacer()
                    }.padding()
                    
                    HStack {
                        if appFile.type == .ipa {
                            ActionButton(
                                title: "Sign & Install",
                                icon: "pencil.and.outline",
                                color: XsignTheme.primary
                            ) {
                                showingSignModal = true
                            }
                        }
                    }.padding()
                    
                    InfoSection(title: "Linked Libraries") {
                        Group {
                            if extractedDylibs.isEmpty {
                                Text("None").font(.caption).foregroundColor(.gray)
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(extractedDylibs, id: \.self) { dylib in
                                        Text(dylib)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(XsignTheme.textPrimary)
                                    }
                                }
                            }
                        }
                    }.padding()
                    
                    InfoSection(title: "Entitlements") {
                        Group {
                            if entitlements.isEmpty {
                                Text("No entitlements found").font(.caption).foregroundColor(.gray)
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(Array(entitlements.keys.sorted()), id: \.self) { key in
                                        VStack(alignment: .leading) {
                                            Text(key)
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(XsignTheme.primary)
                                            Text("\(String(describing: entitlements[key] ?? ""))")
                                                .font(.caption2)
                                                .foregroundColor(XsignTheme.textSecondary)
                                        }.padding(.bottom, 4)
                                    }
                                }
                            }
                        }
                    }.padding()
                }
            }
        }
        .sheet(isPresented: $showingSignModal) {
            SignModalView(appFile: appFile)
        }
        .onAppear {
            if appFile.type == .ipa || appFile.type == .dylib {
                extractedDylibs = BinaryParser.shared.getDylibs(at: appFile.filePath)
            }
            if appFile.type == .ipa {
                // Read the provisioning profile data from the app bundle
                let provisioningProfileURL = appFile.filePath.appendingPathComponent("embedded.mobileprovision")
                if let data = try? Data(contentsOf: provisioningProfileURL) {
                    entitlements = EntitlementManager.shared.extractEntitlements(from: data) ?? [:]
                }
            }
        }
    }
}
