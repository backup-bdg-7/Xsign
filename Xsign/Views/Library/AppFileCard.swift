import SwiftUI

struct AppFileCard: View {
    let appFile: AppFile

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                    .font(.headline).foregroundColor(XsignTheme.textPrimary).lineLimit(1)
                Text(appFile.version ?? "1.0").font(.caption).foregroundColor(XsignTheme.textSecondary)
                HStack {
                    StatusBadge(status: appFile.signatureStatus)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: appFile.size, countStyle: .file))
                        .font(.system(size: 10)).foregroundColor(XsignTheme.textSecondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(12).background(XsignTheme.surface).cornerRadius(16)
    }
}
