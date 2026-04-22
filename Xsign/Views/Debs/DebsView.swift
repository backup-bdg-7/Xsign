import SwiftUI
import SwiftData

struct DebsView: View {
    @Query(filter: #Predicate<AppFile> { $0.type == .deb }) private var debs: [AppFile]
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()

                if debs.isEmpty {
                    ContentUnavailableView("No Debs", systemImage: "archivebox.fill", description: Text("Import .deb files to manage tweaks."))
                } else {
                    List(debs) { deb in
                        NavigationLink(destination: AppDetailView(appFile: deb)) {
                            HStack {
                                Image(systemName: "package.fill")
                                    .foregroundColor(XsignTheme.primary)
                                VStack(alignment: .leading) {
                                    Text(deb.name).foregroundColor(XsignTheme.textPrimary)
                                    Text(ByteCountFormatter.string(fromByteCount: deb.size, countStyle: .file))
                                        .font(.caption).foregroundColor(XsignTheme.textSecondary)
                                }
                            }
                        }
                        .listRowBackground(XsignTheme.surface)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Debs")
            .searchable(text: $searchText)
        }
    }
}
