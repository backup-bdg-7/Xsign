import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }
            
            XSignView()
                .tabItem { Label("XSign", systemImage: "signature") }
            
            GeneralView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .accentColor(XsignTheme.primary)
    }
}
