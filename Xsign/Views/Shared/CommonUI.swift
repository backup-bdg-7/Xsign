import SwiftUI

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
