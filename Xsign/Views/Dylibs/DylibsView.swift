import SwiftUI
import SwiftData

struct DylibsView: View {
    @Query(filter: #Predicate<AppFile> { $0.type == .dylib }) private var dylibs: [AppFile]
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()

                if dylibs.isEmpty {
                    ContentUnavailableView("No Dylibs", systemImage: "bolt.fill", description: Text("Import .dylib files to inject them into apps."))
                } else {
                    List(dylibs) { dylib in
                        NavigationLink(destination: AppDetailView(appFile: dylib)) {
                            HStack {
                                Image(systemName: "bolt.horizontal.circle.fill")
                                    .foregroundColor(XsignTheme.primary)
                                VStack(alignment: .leading) {
                                    Text(dylib.name).foregroundColor(XsignTheme.textPrimary)
                                    Text(ByteCountFormatter.string(fromByteCount: dylib.size, countStyle: .file))
                                        .font(.caption).foregroundColor(XsignTheme.textSecondary)
                                }
                            }
                        }
                        .listRowBackground(XsignTheme.surface)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Dylibs")
            .searchable(text: $searchText)
        }
    }
}
