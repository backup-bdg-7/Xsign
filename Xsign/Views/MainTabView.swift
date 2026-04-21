import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0

    init() {
        UITabBar.appearance().backgroundColor = UIColor(XsignTheme.surface)
        UITabBar.appearance().unselectedItemTintColor = UIColor(XsignTheme.textSecondary)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(0)

            CategoriesView()
                .tabItem {
                    Label("Categories", systemImage: "square.grid.2x2.fill")
                }
                .tag(1)

            DylibsView()
                .tabItem {
                    Label("Dylibs", systemImage: "bolt.fill")
                }
                .tag(2)

            DebsView()
                .tabItem {
                    Label("Debs", systemImage: "archivebox.fill")
                }
                .tag(3)

            GeneralView()
                .tabItem {
                    Label("General", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .accentColor(XsignTheme.primary)
    }
}
