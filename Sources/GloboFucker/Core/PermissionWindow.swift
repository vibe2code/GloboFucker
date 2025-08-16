import Cocoa

class PermissionWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 580),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.contentMinSize = NSSize(width: 800, height: 520)
        self.init(window: window)
        self.window?.contentViewController = PermissionViewController()
    }
} 