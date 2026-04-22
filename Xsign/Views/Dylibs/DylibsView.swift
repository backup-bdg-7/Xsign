import SwiftUI
import SwiftData

struct DylibsView: View {
    @Query(filter: #Predicate<AppFile> { $0.type == .dylib }) private var dylibs: [AppFile]
    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()
                if dylibs.isEmpty { ContentUnavailableView("No Dylibs", systemImage: "bolt.fill") }
                else {
                    List(dylibs) { dylib in
                        NavigationLink(destination: AppDetailView(appFile: dylib)) {
                            HStack {
                                Image(systemName: "bolt.horizontal.circle.fill").foregroundColor(XsignTheme.primary)
                                Text(dylib.name).foregroundColor(XsignTheme.textPrimary)
                            }
                        }.listRowBackground(XsignTheme.surface)
                    }.listStyle(.plain)
                }
            }.navigationTitle("Dylibs")
        }
    }
}
