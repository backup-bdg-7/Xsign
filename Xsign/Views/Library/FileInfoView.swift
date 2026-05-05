import SwiftUI
import SwiftData

struct FileInfoView: View {
    let appFile: AppFile
    @State private var extractedDylibs: [String] = []
    @State private var fileSize: String = ""
    
    var body: some View {
        ZStack {
            XsignTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    // File icon
                    RoundedRectangle(cornerRadius: 22)
                        .fill(XsignTheme.surface)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: iconForType(appFile.type))
                                .font(.system(size: 50))
                                .foregroundColor(XsignTheme.primary)
                        )
                    
                    // File info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(appFile.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(XsignTheme.textPrimary)
                        
                        if let bundleID = appFile.bundleID {
                            Text(bundleID)
                                .font(.caption)
                                .foregroundColor(XsignTheme.textSecondary)
                        }
                        
                        Text("Type: \(appFile.type.rawValue.uppercased())")
                            .font(.caption)
                            .foregroundColor(XsignTheme.textSecondary)
                        
                        if let version = appFile.version {
                            Text("Version: \(version)")
                                .font(.caption)
                                .foregroundColor(XsignTheme.textSecondary)
                        }
                        
                        Text("Size: \(fileSize)")
                            .font(.caption)
                            .foregroundColor(XsignTheme.textSecondary)
                        
                        Text("Created: \(appFile.creationDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(XsignTheme.textSecondary)
                        
                        StatusBadge(status: appFile.signatureStatus)
                            .padding(.top, 4)
                    }
                    
                    // Linked libraries (for dylib files)
                    if appFile.type == .dylib || appFile.type == .ipa {
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
                        }
                        .padding()
                    }
                    
                    // Entitlements (for ipa files)
                    if appFile.type == .ipa {
                        InfoSection(title: "Entitlements") {
                            Text("Check Signing Options for entitlements")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            if appFile.type == .dylib || appFile.type == .ipa {
                extractedDylibs = BinaryParser.shared.getDylibs(at: appFile.filePath)
            }
            fileSize = ByteCountFormatter.string(fromByteCount: appFile.size, countStyle: .file)
        }
    }
    
    private func iconForType(_ type: FileType) -> String {
        switch type {
        case .ipa: return "app.fill"
        case .dylib: return "curl"
        case .deb: return "cylinder.split.1x2"
        case .tipa: return "app.badge.checkmark"
        case .zip: return "doc.zipper"
        }
    }
}

#Preview {
    if let appFile = try? PersistenceService.shared.context.fetch(FetchDescriptor<AppFile>()).first {
        FileInfoView(appFile: appFile)
    }
}
