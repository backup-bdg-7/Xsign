import SwiftUI
import SwiftData

struct AppDetailView: View {
    let appFile: AppFile

    @State private var showingSignModal = false

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
                                Image(systemName: "app.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(XsignTheme.primary)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(appFile.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(XsignTheme.textPrimary)

                            Text(appFile.bundleID ?? "com.example.app")
                                .font(.subheadline)
                                .foregroundColor(XsignTheme.textSecondary)

                            HStack {
                                Text("v\(appFile.version ?? "1.0")")
                                Text("•")
                                Text("Build \(appFile.build ?? "1")")
                            }
                            .font(.caption)
                            .foregroundColor(XsignTheme.textSecondary)

                            StatusBadge(status: appFile.signatureStatus)
                                .padding(.top, 4)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Actions
                    HStack(spacing: 16) {
                        ActionButton(title: "Sign & Install", icon: "pencil.and.outline", color: XsignTheme.primary) {
                            showingSignModal = true
                        }

                        ActionButton(title: "Export", icon: "square.and.arrow.up", color: XsignTheme.surface) {
                            // Export logic
                        }
                    }
                    .padding(.horizontal)

                    // Info Sections
                    VStack(alignment: .leading, spacing: 16) {
                        InfoSection(title: "File Details") {
                            InfoRow(label: "Filename", value: appFile.fileName)
                            InfoRow(label: "Size", value: ByteCountFormatter.string(fromByteCount: appFile.size, countStyle: .file))
                            InfoRow(label: "Added", value: appFile.creationDate.formatted(date: .abbreviated, time: .shortened))
                            if let lastSigned = appFile.lastSignedDate {
                                InfoRow(label: "Last Signed", value: lastSigned.formatted(date: .abbreviated, time: .shortened))
                            }
                        }

                        if let entitlements = appFile.entitlements, !entitlements.isEmpty {
                            InfoSection(title: "Entitlements") {
                                ForEach(entitlements) { entitlement in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(entitlement.name)
                                                .font(.subheadline)
                                                .foregroundColor(XsignTheme.textPrimary)
                                            Text(entitlement.entitlementDescription)
                                                .font(.caption2)
                                                .foregroundColor(XsignTheme.textSecondary)
                                        }
                                        Spacer()
                                        if entitlement.isRequired {
                                            Text("Required")
                                                .font(.system(size: 8))
                                                .padding(4)
                                                .background(XsignTheme.error.opacity(0.2))
                                                .foregroundColor(XsignTheme.error)
                                                .cornerRadius(4)
                                        }
                                    }
                                    .padding(.vertical, 4)
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
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}

struct InfoSection<Content: View>: View {
    let title: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(XsignTheme.textPrimary)

            VStack(spacing: 0) {
                content()
            }
            .padding()
            .background(XsignTheme.surface)
            .cornerRadius(12)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(XsignTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundColor(XsignTheme.textPrimary)
        }
        .font(.subheadline)
        .padding(.vertical, 8)
        if label != "Added" && label != "Last Signed" { // Simple separator logic
             Divider().background(XsignTheme.textSecondary.opacity(0.1))
        }
    }
}
