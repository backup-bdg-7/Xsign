import Foundation

// Simulated validation script for Xsign
print("--- Starting Xsign Validation ---")

let files = [
    "Xsign/App/XsignApp.swift",
    "Xsign/Models/AppFile.swift",
    "Xsign/Models/Certificate.swift",
    "Xsign/Models/Category.swift",
    "Xsign/Models/Entitlement.swift",
    "Xsign/Models/AppLog.swift",
    "Xsign/Shared/Theme.swift",
    "Xsign/Views/MainTabView.swift",
    "Xsign/Services/PersistenceService.swift",
    "Xsign/Services/SigningService.swift",
    "Xsign/Services/FileService.swift",
    "Xsign/Services/LocalServerService.swift"
]

var missingFiles = 0
for file in files {
    if FileManager.default.fileExists(atPath: file) {
        print("✅ \(file) exists")
    } else {
        print("❌ \(file) is missing")
        missingFiles += 1
    }
}

if missingFiles == 0 {
    print("\n--- Validation Successful ---")
} else {
    print("\n--- Validation Failed: \(missingFiles) files missing ---")
    exit(1)
}
