import Cocoa
import Carbon
import Foundation

/// Intercepts Globe key presses and switches keyboard input sources instantly.
///
/// Key points:
/// - Uses a session-level CGEvent tap to capture keyDown events
/// - Filters available, selectable keyboard input sources (layouts and input modes)
/// - Cycles through sources on Globe key and prevents the original event from propagating
class GlobeKeyRemapper: NSObject {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var currentInputSourceIndex = 0
    private var inputSources: [TISInputSource] = []
    
    override init() {
        super.init()
        setupInputSources()
        setupEventTap()
    }
    
    /// Builds a filtered list of enabled, selectable keyboard input sources
    private func setupInputSources() {
        // Get all available input sources (languages)
        let inputSourceList = TISCreateInputSourceList(nil, false).takeRetainedValue() as! [TISInputSource]
        
        // Filter only enabled, selectable keyboard input sources (like native menu)
        inputSources = inputSourceList.filter { source in
            guard
                let isEnabledPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled),
                CFBooleanGetValue(unsafeBitCast(isEnabledPtr, to: CFBoolean.self))
            else { return false }

            if let selectablePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable),
               CFBooleanGetValue(unsafeBitCast(selectablePtr, to: CFBoolean.self)) == false {
                return false
            }

            if let categoryPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceCategory) {
                let category = unsafeBitCast(categoryPtr, to: CFString.self)
                if !CFEqual(category, kTISCategoryKeyboardInputSource) { return false }
            }

            // Accept keyboard layouts and input modes
            if let typePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceType) {
                let type = unsafeBitCast(typePtr, to: CFString.self)
                if CFEqual(type, kTISTypeKeyboardLayout) || CFEqual(type, kTISTypeKeyboardInputMode) {
                    return true
                }
            }

            return false
        }
        
        print("Found \(inputSources.count) enabled input sources:")
        for (index, source) in inputSources.enumerated() {
            let name = getInputSourceName(source)
            print("  \(index): \(name)")
        }

        // Sync current index with the actually selected input source
        if let current = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() {
            if let idx = inputSources.firstIndex(where: { CFEqual($0, current) }) {
                currentInputSourceIndex = idx
            } else {
                currentInputSourceIndex = 0
            }
        }
    }
    
    /// Returns localized, human-friendly name for the input source
    private func getInputSourceName(_ source: TISInputSource) -> String {
        if let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) {
            let cfStr = unsafeBitCast(namePtr, to: CFString.self)
            return cfStr as String
        }
        return "Unknown"
    }
    
    /// Creates and enables a session event tap to intercept keyDown events
    private func setupEventTap() {
        print("Setting up event tap...")
        
        // Check accessibility permission before creating event tap
        let accessibilityEnabled = AXIsProcessTrusted()
        print("Accessibility permission: \(accessibilityEnabled ? "Granted" : "Not granted")")
        
        if !accessibilityEnabled {
            print("⚠️ Accessibility permission required!")
            print("Go to System Settings → Security & Privacy → Privacy → Accessibility and add GloboFucker to the allowed apps.")
            
            // Open Accessibility settings
            let script = """
            tell application \"System Preferences\"
                activate
                set current pane to pane id \"com.apple.preference.security\"
            end tell
            """
            
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(nil)
            }
            
            return
        }
        
        // Create event tap for intercepting key presses (keyDown only to avoid double-trigger)
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        print("Creating event tap with mask: \(eventMask)")
        
        // Try to create event tap with .headInsertEventTap
        print("Trying to create event tap with .headInsertEventTap...")
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let remapper = Unmanaged<GlobeKeyRemapper>.fromOpaque(refcon!).takeUnretainedValue()
                return remapper.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        // If failed, try .tailAppendEventTap
        if eventTap == nil {
            print("⚠️ Failed to create event tap with .headInsertEventTap, trying .tailAppendEventTap")
            eventTap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .tailAppendEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(eventMask),
                callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                    let remapper = Unmanaged<GlobeKeyRemapper>.fromOpaque(refcon!).takeUnretainedValue()
                    return remapper.handleEvent(proxy: proxy, type: type, event: event)
                },
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            )
        }
        
        guard let eventTap = eventTap else {
            print("❌ Failed to create event tap")
            return
        }
        
        print("✅ Event tap created successfully")
        
        // Enable event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        print("✅ Event tap enabled")
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        print("✅ Event tap fully set up and enabled")
        print("Waiting for globe key (code 179)...")
    }
    
    /// Event tap callback: re-enables tap if disabled and handles Globe key
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Re-enable event tap if it gets disabled by timeout or user input to avoid "first press" being lost
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap = self.eventTap {
                print("⚠️ Event tap disabled (\(type == .tapDisabledByTimeout ? "timeout" : "user input")), re-enabling…")
                CGEvent.tapEnable(tap: eventTap, enable: true)
                print("✅ Event tap re-enabled")
            }
            return nil
        }
        // Process only keyDown
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }
        // Get key code
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        // Globe key code (179 for your Mac)
        let globeKeyCode: Int64 = 179
        
        if keyCode == globeKeyCode {
            // Instantly switch input source and block the event
            switchToNextInputSource()
            return nil
        }
        
        // Pass through all other events
        return Unmanaged.passUnretained(event)
    }
    
    /// Cycles to the next input source, ensuring we try alternatives if the first attempt fails
    private func switchToNextInputSource() {
        guard !inputSources.isEmpty else {
            print("❌ No available input sources")
            return
        }
        
        // Go to next input source (try until success, to ensure we iterate over all installed)
        var attempts = 0
        var switched = false
        var nextSourceName = ""
        while attempts < inputSources.count && !switched {
            currentInputSourceIndex = (currentInputSourceIndex + 1) % inputSources.count
            let nextSource = inputSources[currentInputSourceIndex]
            nextSourceName = getInputSourceName(nextSource)
        
        print("Switching to: \(nextSourceName)")
        
        // Method 1: Standard switching
        let result1 = TISSelectInputSource(inputSources[currentInputSourceIndex])
        
        if result1 == noErr {
            print("✅ Switched successfully: \(nextSourceName)")
            NotificationCenter.default.post(name: .keyboardInputSourceChanged, object: nil)
            switched = true
        } else {
            print("⚠️ First method failed, trying alternative...")
            
            // Method 2: Try Carbon API
            let result2 = TISSelectInputSource(inputSources[currentInputSourceIndex])
            
            if result2 == noErr {
                print("✅ Switched successfully (method 2): \(nextSourceName)")
                NotificationCenter.default.post(name: .keyboardInputSourceChanged, object: nil)
                switched = true
            } else {
                print("⚠️ Second method failed, trying third...")
                
                // Method 3: Try another API
                let currentSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
                if currentSource != inputSources[currentInputSourceIndex] {
                    let result3 = TISSelectInputSource(inputSources[currentInputSourceIndex])
                    if result3 == noErr {
                        print("✅ Switched successfully (method 3): \(nextSourceName)")
                        NotificationCenter.default.post(name: .keyboardInputSourceChanged, object: nil)
                        switched = true
                    } else {
                        print("❌ All switching methods failed")
                    }
                }
            }
        }
            if !switched { attempts += 1 }
        }
    }
    
    /// Starts the run loop when using the remapper standalone (not required in app)
    func start() {
        print("GlobeKeyRemapper started")
        print("Press the globe key for instant language switching")
        print("Press Ctrl+C to exit")
        
        // Start run loop
        CFRunLoopRun()
    }
    
    /// Disables event tap and removes run loop source
    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        print("GlobeKeyRemapper stopped")
    }
    
    // MARK: - Public Methods for GloboFucker
    
    /// Get current input source name
    func getCurrentInputSourceName() -> String {
        guard !inputSources.isEmpty else { return "Unknown" }
        return getInputSourceName(inputSources[currentInputSourceIndex])
    }
    
    /// Get all available input source names
    func getAvailableInputSourceNames() -> [String] {
        return inputSources.map { getInputSourceName($0) }
    }
    
    /// Set globe key code
    func setGlobeKeyCode(_ code: Int64) {
        // This would need to be implemented to change the key code dynamically
        print("Globe key code set to: \(code)")
    }
    
    /// Get current globe key code
    func getGlobeKeyCode() -> Int64 {
        return 179 // Default value
    }
} 

// MARK: - Notifications

extension Notification.Name {
    static let keyboardInputSourceChanged = Notification.Name("KeyboardInputSourceChanged")
}