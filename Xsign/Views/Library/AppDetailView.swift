import SwiftUI
import SwiftData

struct AppDetailView: View {
    let appFile: AppFile

    @State private var showingSignModal = false
    @State private var showingEntitlements = false

    var body: some View {
        ZStack {
            XsignTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack(spacing: 20) {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(XsignTheme.surface)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: appFile.type == .ipa ? "app.fill" : "bolt.horizontal.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(XsignTheme.primary)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(appFile.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(XsignTheme.textPrimary)
                                .lineLimit(2)

                            if let bundleID = appFile.bundleID {
                                Text(bundleID)
                                    .font(.caption)
                                    .foregroundColor(XsignTheme.textSecondary)
                            }

                            HStack {
                                Text("v\(appFile.version ?? "1.0")")
                                Text("•")
                                Text(ByteCountFormatter.string(fromByteCount: appFile.size, countStyle: .file))
                            }
                            .font(.system(size: 10))
                            .foregroundColor(XsignTheme.textSecondary)

                            StatusBadge(status: appFile.signatureStatus)
                                .padding(.top, 4)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Actions
                    HStack(spacing: 16) {
                        if appFile.type == .ipa {
                            ActionButton(title: "Sign & Install", icon: "pencil.and.outline", color: XsignTheme.primary) {
                                showingSignModal = true
                            }
                        }

                        ActionButton(title: "Export", icon: "square.and.arrow.up", color: XsignTheme.surface) {
                            // Export logic
                        }
                    }
                    .padding(.horizontal)

                    // Info Sections
                    VStack(alignment: .leading, spacing: 16) {
                        InfoSection(title: "File Information") {
                            InfoRow(label: "Format", value: appFile.type.rawValue.uppercased())
                            InfoRow(label: "Added On", value: appFile.creationDate.formatted(date: .abbreviated, time: .shortened))
                            if let lastSigned = appFile.lastSignedDate {
                                InfoRow(label: "Last Signed", value: lastSigned.formatted(date: .abbreviated, time: .shortened))
                            }
                        }

                        if let entitlements = appFile.entitlements, !entitlements.isEmpty {
                            InfoSection(title: "App Entitlements") {
                                ForEach(entitlements.prefix(3)) { entitlement in
                                    Text(entitlement.name)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(XsignTheme.textPrimary)
                                        .padding(.vertical, 4)
                                }

                                if entitlements.count > 3 {
                                    Button("View All \(entitlements.count) Entitlements") {
                                        showingEntitlements = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(XsignTheme.primary)
                                    .padding(.top, 8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSignModal) {
            SignModalView(appFile: appFile)
        }
        .sheet(isPresented: $showingEntitlements) {
            NavigationStack {
                List(appFile.entitlements ?? []) { entitlement in
                    Text(entitlement.name)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(XsignTheme.textPrimary)
                        .listRowBackground(XsignTheme.surface)
                }
                .navigationTitle("Entitlements")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button("Close") { showingEntitlements = false }
                }
            }
        }
    }
}
