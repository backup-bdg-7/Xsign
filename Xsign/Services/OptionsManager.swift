import Foundation

// MARK: - Options Manager
// Based on Feather's OptionsManager
class OptionsManager: ObservableObject {
    static let shared = OptionsManager()
    
    @Published var options: SigningOptions {
        didSet {
            saveOptions()
        }
    }
    
    private let userDefaultsKey = "xsign.signing.options"
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedOptions = try? JSONDecoder().decode(SigningOptions.self, from: data) {
            self.options = savedOptions
        } else {
            self.options = SigningOptions()
        }
    }
    
    private func saveOptions() {
        if let data = try? JSONEncoder().encode(options) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}
