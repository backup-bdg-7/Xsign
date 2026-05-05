import SwiftUI
import SwiftData

@main
struct XsignApp: App {
    init() {
        // Setup folder structure on launch
        FolderSetup.shared
    }
    
    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .modelContainer(for: [AppFile.self, Certificate.self, Category.self, Entitlement.self, AppLog.self])
                .preferredColorScheme(.dark)
        }
    }
}
