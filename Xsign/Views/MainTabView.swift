import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical") }

            CategoriesView()
                .tabItem { Label("Categories", systemImage: "square.grid.2x2") }

            DylibsView()
                .tabItem { Label("Dylibs", systemImage: "bolt.fill") }

            DebsView()
                .tabItem { Label("Debs", systemImage: "archivebox.fill") }

            GeneralView()
                .tabItem { Label("General", systemImage: "gear") }
        }
        .accentColor(XsignTheme.primary)
    }
}
