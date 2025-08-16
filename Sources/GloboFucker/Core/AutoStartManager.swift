import Foundation
import ServiceManagement

/// Manager for handling application auto-start functionality
class AutoStartManager {
    
    // MARK: - Singleton
    
    static let shared = AutoStartManager()
    
    // MARK: - Properties
    
    private let bundleIdentifier = "com.globofucker.app"
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Check if auto-start is enabled
    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return UserDefaults.standard.bool(forKey: "autoStartEnabled")
        }
    }
    
    /// Toggle auto-start
    func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }
    
    /// Enable auto-start
    func enable() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
                print("✅ Auto-start enabled using SMAppService")
            } catch {
                print("❌ Failed to enable auto-start: \(error)")
            }
        } else {
            // Legacy method for older macOS versions
            enableLegacy()
        }
    }
    
    /// Disable auto-start
    func disable() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
                print("✅ Auto-start disabled using SMAppService")
            } catch {
                print("❌ Failed to disable auto-start: \(error)")
            }
        } else {
            // Legacy method for older macOS versions
            disableLegacy()
        }
    }
    
    // MARK: - Legacy Methods (for macOS < 13.0)
    
    /// Enable auto-start using legacy method
    private func enableLegacy() {
        let appPath = Bundle.main.bundlePath
        let script = """
        tell application "System Events"
            make login item at end with properties {path:"\(appPath)", hidden:true}
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            if let error = error {
                print("❌ Failed to enable auto-start: \(error)")
            } else {
                UserDefaults.standard.set(true, forKey: "autoStartEnabled")
                print("✅ Auto-start enabled using legacy method")
            }
        }
    }
    
    /// Disable auto-start using legacy method
    private func disableLegacy() {
        let appPath = Bundle.main.bundlePath
        let script = """
        tell application "System Events"
            delete login item "\(appPath)"
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            if let error = error {
                print("❌ Failed to disable auto-start: \(error)")
            } else {
                UserDefaults.standard.set(false, forKey: "autoStartEnabled")
                print("✅ Auto-start disabled using legacy method")
            }
        }
    }
} 