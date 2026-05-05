import SwiftUI
import SwiftData

@main
struct XsignApp: App {
    init() {
        // Setup folder structure on launch
        FolderSetup.shared
        
        // Create default categories (needs to be on main actor)
        Task { @MainActor in
            PersistenceService.shared.createDefaultCategories()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .modelContainer(for: [AppFile.self, Certificate.self, Category.self, Entitlement.self, AppLog.self])
                .preferredColorScheme(.dark)
        }
    }
}
