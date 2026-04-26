import SwiftUI

struct StatusBadge: View {
    let status: SignatureStatus
    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 8, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 2)
            .background(backgroundColor.opacity(0.2)).foregroundColor(backgroundColor).cornerRadius(4)
    }
    var backgroundColor: Color {
        switch status {
        case .signed: return XsignTheme.success
        case .failed, .invalid: return XsignTheme.error
        case .unsigned: return XsignTheme.textSecondary
        }
    }
}
