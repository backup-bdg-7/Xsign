import SwiftUI

struct AppFileCard: View {
    let appFile: AppFile

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(XsignTheme.secondary.opacity(0.3))
                    .frame(height: 100)

                Image(systemName: "app.fill")
                    .font(.system(size: 40))
                    .foregroundColor(XsignTheme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(appFile.name)
                    .font(.headline)
                    .foregroundColor(XsignTheme.textPrimary)
                    .lineLimit(1)

                Text(appFile.version ?? "Unknown Version")
                    .font(.caption)
                    .foregroundColor(XsignTheme.textSecondary)

                HStack {
                    StatusBadge(status: appFile.signatureStatus)
                    Spacer()
                    Text("\(ByteCountFormatter.string(fromByteCount: appFile.size, countStyle: .file))")
                        .font(.system(size: 10))
                        .foregroundColor(XsignTheme.textSecondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(XsignTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(XsignTheme.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

struct AppFileListRow: View {
    let appFile: AppFile

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(XsignTheme.secondary.opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "app.fill")
                        .foregroundColor(XsignTheme.primary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(appFile.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(XsignTheme.textPrimary)

                Text(appFile.bundleID ?? "com.example.app")
                    .font(.caption2)
                    .foregroundColor(XsignTheme.textSecondary)
            }

            Spacer()

            StatusBadge(status: appFile.signatureStatus)
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: SignatureStatus

    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor.opacity(0.2))
            .foregroundColor(backgroundColor)
            .cornerRadius(4)
    }

    var backgroundColor: Color {
        switch status {
        case .signed: return XsignTheme.success
        case .failed, .invalid: return XsignTheme.error
        case .unsigned: return XsignTheme.textSecondary
        }
    }
}
