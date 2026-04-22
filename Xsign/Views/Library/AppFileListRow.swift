import SwiftUI
import SwiftData

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
