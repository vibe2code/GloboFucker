import Foundation

/// Language information structure
struct Language {
    let code: String
    let displayName: String
    let nativeName: String
}

/// Manager responsible for application localization lifecycle.
///
/// Responsibilities:
/// - Discovers available languages under `Resources/Languages`
/// - Loads JSON translations for the selected language
/// - Provides string lookup with a safe fallback to English
/// - Persists selected language in `UserDefaults`
class LocalizationManager {
    
    // MARK: - Singleton
    
    static let shared = LocalizationManager()
    
    // MARK: - Properties
    
    private var currentLanguage: String = "en"
    private var translations: [String: String] = [:]
    private var fallbackTranslations: [String: String] = [:]
    private let fallbackLanguage: String = "en"
    var availableLanguages: [Language] = []
    
    // MARK: - Initialization
    
    private init() {
        loadAvailableLanguages()
    }
    
    /// Enumerates all JSON files in `Resources/Languages` and builds the language list
    private func loadAvailableLanguages() {
        availableLanguages = []
        let fileManager = FileManager.default
        guard let languagesURL = Bundle.main.resourceURL?.appendingPathComponent("Languages") else { return }
        guard let files = try? fileManager.contentsOfDirectory(at: languagesURL, includingPropertiesForKeys: nil) else { return }
        for file in files where file.pathExtension == "json" {
            let code = file.deletingPathExtension().lastPathComponent
            if let data = try? Data(contentsOf: file),
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                let displayName = json["lang_name"] ?? code
                let nativeName = json["lang_name"] ?? code
                availableLanguages.append(Language(code: code, displayName: displayName, nativeName: nativeName))
            } else {
                availableLanguages.append(Language(code: code, displayName: code, nativeName: code))
            }
        }
        // Sort by displayName for nice menu
        availableLanguages.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
    
    /// Initialize localization system
    func initialize() {
        loadAvailableLanguages()
        // Load saved language preference or detect from system
        if let saved = UserDefaults.standard.string(forKey: "selectedLanguage") {
            currentLanguage = saved
        } else {
            currentLanguage = detectSystemLanguage(fallback: "en")
        }
        // Preload fallback (English) once, then active language
        fallbackTranslations = loadTranslations(for: fallbackLanguage)
        loadTranslations()
    }

    private func detectSystemLanguage(fallback: String) -> String {
        let preferred = Locale.preferredLanguages.first ?? fallback
        let code = preferred.components(separatedBy: CharacterSet(charactersIn: "-_")).first?.lowercased() ?? fallback
        if let base = Bundle.main.resourceURL?.appendingPathComponent("Languages/\(code).json"),
           FileManager.default.fileExists(atPath: base.path) {
            return code
        }
        return fallback
    }
    
    // MARK: - Language Management
    
    /// Set current language
    func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode
        UserDefaults.standard.set(languageCode, forKey: "selectedLanguage")
        loadTranslations()
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
    
    /// Get current language code
    func getCurrentLanguage() -> String {
        return currentLanguage
    }
    
    // MARK: - Translation Methods
    
    /// Get localized string for key. Falls back to English if the key is missing.
    func localizedString(_ key: String) -> String {
        return translations[key] ?? fallbackTranslations[key] ?? key
    }
    
    /// Load translations for current language (no default bundled strings; use only Languages/*.json)
    private func loadTranslations() {
        translations = loadTranslations(for: currentLanguage)
    }

    /// Reads a JSON file for a specific language into a dictionary
    private func loadTranslations(for languageCode: String) -> [String: String] {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("Languages/\(languageCode).json"),
              FileManager.default.fileExists(atPath: url.path) else {
            if languageCode != fallbackLanguage {
                print("⚠️ Translation file not found for language: \(languageCode)")
            }
            return [:]
        }
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] ?? [:]
            return json
        } catch {
            print("❌ Error loading translations for \(languageCode): \(error)")
            return [:]
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
    static let accessibilityPermissionGranted = Notification.Name("accessibilityPermissionGranted")
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
} 