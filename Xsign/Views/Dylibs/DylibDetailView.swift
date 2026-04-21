import SwiftUI

struct DylibDetailView: View {
    let appFile: AppFile
    @State private var info: MachOInfo?

    var body: some View {
        ZStack {
            XsignTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack {
                        Image(systemName: "bolt.horizontal.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(XsignTheme.primary)
                        Text(appFile.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(XsignTheme.textPrimary)
                    }
                    .padding()

                    if let info = info {
                        InfoSection(title: "Architectures") {
                            ForEach(info.architectures, id: \.self) { arch in
                                Text(arch)
                                    .font(.subheadline)
                                    .foregroundColor(XsignTheme.textPrimary)
                                    .padding(.vertical, 4)
                            }
                        }

                        InfoSection(title: "Platform") {
                            InfoRow(label: "Target", value: info.platform)
                            InfoRow(label: "Min OS", value: info.minOS)
                        }
                    } else {
                        ProgressView().tint(XsignTheme.primary)
                    }

                    ActionButton(title: "Inject into IPA", icon: "plus.square.on.square", color: XsignTheme.primary) {
                        // Injection logic
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            info = BinaryParser.shared.parseMachO(at: appFile.filePath)
        }
    }
}

struct DebDetailView: View {
    let appFile: AppFile
    @State private var info: DebInfo?

    var body: some View {
        ZStack {
            XsignTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    VStack {
                        Image(systemName: "package.fill")
                            .font(.system(size: 60))
                            .foregroundColor(XsignTheme.primary)
                        Text(appFile.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(XsignTheme.textPrimary)
                    }
                    .padding()

                    if let info = info {
                        InfoSection(title: "Package Info") {
                            InfoRow(label: "Package", value: info.packageName)
                            InfoRow(label: "Version", value: info.version)
                            InfoRow(label: "Arch", value: info.architecture)
                            InfoRow(label: "Maintainer", value: info.maintainer)
                        }

                        InfoSection(title: "Description") {
                            Text(info.description)
                                .font(.caption)
                                .foregroundColor(XsignTheme.textSecondary)
                                .padding(.vertical, 4)
                        }
                    } else {
                        ProgressView().tint(XsignTheme.primary)
                    }
                }
            }
        }
        .onAppear {
            info = BinaryParser.shared.parseDeb(at: appFile.filePath)
        }
    }
}
