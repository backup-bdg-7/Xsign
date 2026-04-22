import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }

            CategoriesView()
                .tabItem { Label("Categories", systemImage: "square.grid.2x2.fill") }

            DylibsView()
                .tabItem { Label("Dylibs", systemImage: "bolt.fill") }

            DebsView()
                .tabItem { Label("Debs", systemImage: "archivebox.fill") }

            GeneralView()
                .tabItem { Label("General", systemImage: "gearshape.fill") }
        }
        .accentColor(XsignTheme.primary)
    }
}
