import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }

            GeneralView()
                .tabItem { Label("General", systemImage: "gearshape.fill") }
        }
        .accentColor(XsignTheme.primary)
    }
}
