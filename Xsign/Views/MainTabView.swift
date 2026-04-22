import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            LibraryView().tabItem { Label("Library", systemImage: "books.vertical") }
            GeneralView().tabItem { Label("General", systemImage: "gear") }
        }.accentColor(XsignTheme.primary)
    }
}
