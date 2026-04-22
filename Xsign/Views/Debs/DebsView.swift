import SwiftUI
import SwiftData

struct DebsView: View {
    @Query(filter: #Predicate<AppFile> { $0.type == .deb }) private var debs: [AppFile]
    var body: some View {
        NavigationStack {
            ZStack {
                XsignTheme.background.ignoresSafeArea()
                if debs.isEmpty { ContentUnavailableView("No Debs", systemImage: "archivebox.fill") }
                else {
                    List(debs) { deb in
                        NavigationLink(destination: AppDetailView(appFile: deb)) {
                            HStack {
                                Image(systemName: "package.fill").foregroundColor(XsignTheme.primary)
                                Text(deb.name).foregroundColor(XsignTheme.textPrimary)
                            }
                        }.listRowBackground(XsignTheme.surface)
                    }.listStyle(.plain)
                }
            }.navigationTitle("Debs")
        }
    }
}
