import SwiftUI
import SwiftData

struct AppDetailView: View {
    let appFile: AppFile
    @State private var showingSignModal = false
    @State private var extractedDylibs: [String] = []

    var body: some View {
        ZStack {
            XsignTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    HStack(spacing: 20) {
                        RoundedRectangle(cornerRadius: 22).fill(XsignTheme.surface).frame(width: 100, height: 100)
                            .overlay(Image(systemName: "app.fill").font(.system(size: 50)).foregroundColor(XsignTheme.primary))
                        VStack(alignment: .leading) {
                            Text(appFile.name).font(.title3).fontWeight(.bold).foregroundColor(XsignTheme.textPrimary)
                            Text(appFile.bundleID ?? "No Bundle ID").font(.caption).foregroundColor(XsignTheme.textSecondary)
                            StatusBadge(status: appFile.signatureStatus).padding(.top, 4)
                        }
                        Spacer()
                    }.padding()

                    HStack(spacing: 16) {
                        if appFile.type == .ipa {
                            ActionButton(title: "Sign & Install", icon: "pencil.and.outline", color: XsignTheme.primary) {
                                showingSignModal = true
                            }
                        }
                    }.padding()

                    InfoSection(title: "File Details") {
                        InfoRow(label: "Format", value: appFile.type.rawValue.uppercased())
                        InfoRow(label: "Size", value: ByteCountFormatter.string(fromByteCount: appFile.size, countStyle: .file))
                        if let version = appFile.version { InfoRow(label: "Version", value: version) }
                    }.padding()

                    InfoSection(title: "Binary Analysis") {
                        if extractedDylibs.isEmpty {
                            Text("No external dylibs detected").font(.caption).foregroundColor(XsignTheme.textSecondary)
                        } else {
                            ForEach(extractedDylibs, id: \.self) { dylib in
                                Text(dylib.components(separatedBy: "/").last ?? dylib)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(XsignTheme.textPrimary)
                                    .padding(.vertical, 2)
                            }
                        }
                    }.padding()
                }
            }
        }
        .navigationTitle("Details")
        .sheet(isPresented: $showingSignModal) { SignModalView(appFile: appFile) }
        .onAppear {
            if appFile.type == .ipa || appFile.type == .dylib {
                extractedDylibs = BinaryParser.shared.getDylibs(at: appFile.filePath)
            }
        }
    }
}
