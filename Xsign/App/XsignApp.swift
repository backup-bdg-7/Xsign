import SwiftUI
import SwiftData

@main
struct XsignApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(for: [AppFile.self, Certificate.self, Category.self, Entitlement.self, AppLog.self])
                .preferredColorScheme(.dark)
        }
    }
}
