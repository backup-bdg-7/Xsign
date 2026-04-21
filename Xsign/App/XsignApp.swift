import SwiftUI
import SwiftData

@main
struct XsignApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(PersistenceService.shared.container)
    }
}
