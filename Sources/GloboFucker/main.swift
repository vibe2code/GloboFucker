import Cocoa
import Foundation
import Carbon
// Explicitly import PermissionWindowController and PermissionViewController if needed

let app = NSApplication.shared
let delegate = GloboFuckerAppDelegate()
app.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)

class GloboFuckerAppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var globeKeyRemapper: GlobeKeyRemapper?
    private var permissionWindow: PermissionWindowController?
    private var permissionCheckTimer: Timer?
    private var onboardingWindow: OnboardingWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 GloboFucker starting...")
        LocalizationManager.shared.initialize()
        print("✅ Localization initialized")
        showHelloIfFirstRun()

        // First run or not trusted → show onboarding flow
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") || !AXIsProcessTrusted() {
            NSApp.setActivationPolicy(.regular)
            onboardingWindow = OnboardingWindowController()
            onboardingWindow?.showWindow(nil)
            onboardingWindow?.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            NotificationCenter.default.addObserver(self, selector: #selector(handleOnboardingCompleted), name: .onboardingCompleted, object: nil)
            // Poll permission in background; app will continue after onboarding closes
            permissionCheckTimer?.invalidate()
            permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
                guard let self else { return }
                if AXIsProcessTrusted() {
                    self.permissionCheckTimer?.invalidate()
                    self.permissionCheckTimer = nil
                }
            })
            return
        }

        // If permission is granted, start tray and remapper
        setupStatusBar()
        if statusItem?.button?.image == nil {
            setStatusBarIconToCurrentInputSource()
        }
        print("✅ Status bar setup completed")
        globeKeyRemapper = GlobeKeyRemapper()
        print("✅ Globe key remapper initialized")
        print("🌍 GloboFucker started successfully")

        // Observe our own app's keyboard source changes
        NotificationCenter.default.addObserver(self, selector: #selector(updateStatusBarIcon), name: .keyboardInputSourceChanged, object: nil)
        // Observe system keyboard source changes (native menu etc.)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(updateStatusBarIcon), name: NSNotification.Name(rawValue: kTISNotifySelectedKeyboardInputSourceChanged as String), object: nil)
        // Initial icon sync
        updateStatusBarIcon()
    }

    private func showHelloIfFirstRun() {
        let key = "hasShownHello"
        if !UserDefaults.standard.bool(forKey: key) {
            if let statusItem = statusItem, let button = statusItem.button {
                let popover = NSPopover()
                let vc = NSViewController()
                let label = NSTextField(labelWithString: LocalizationManager.shared.localizedString("hello_popover"))
                label.font = NSFont.systemFont(ofSize: 12)
                label.textColor = .labelColor
                label.alignment = .center
                label.translatesAutoresizingMaskIntoConstraints = false
                vc.view = NSView(frame: NSRect(x: 0, y: 0, width: 160, height: 40))
                vc.view.addSubview(label)
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
                ])
                popover.contentViewController = vc
                popover.behavior = .transient
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    popover.performClose(nil)
                }
            }
            UserDefaults.standard.set(true, forKey: key)
        }
    }

    @objc private func handlePermissionGranted() {
        // Switch to accessory mode and continue normal startup without manual restart
        NSApp.setActivationPolicy(.accessory)
        permissionWindow?.close()
        permissionWindow = nil
        setupStatusBar()
        globeKeyRemapper = GlobeKeyRemapper()
        updateStatusBarIcon()
        showHelloIfFirstRun()
        print("✅ Continued startup after permission grant")
    }

    @objc private func handleOnboardingCompleted() {
        onboardingWindow?.close()
        onboardingWindow = nil
        handlePermissionGranted()
    }

    func applicationWillTerminate(_ notification: Notification) {
        globeKeyRemapper?.stop()
        print("🌍 GloboFucker stopped")
    }

    private func setupStatusBar() {
        print("🔧 Setting up status bar...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            print("✅ Status item button created")
            // Ensure the status item is visible and persistent
            statusItem?.isVisible = true
            if #available(macOS 13.0, *) {
                statusItem?.behavior = [] // do not allow removal
                statusItem?.autosaveName = "com.globofucker.statusitem"
            }
            // Set current layout icon like native input menu
            setStatusBarIconToCurrentInputSource()
            button.imagePosition = .imageLeft
            button.imageScaling = .scaleProportionallyDown
        }
        let menu = NSMenu()
        let statusMenuItem = NSMenuItem(title: LocalizationManager.shared.localizedString("status_active"), action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menu.addItem(NSMenuItem.separator())
        let languageMenu = NSMenu()
        let languageItem = NSMenuItem(title: LocalizationManager.shared.localizedString("language"), action: nil, keyEquivalent: "")
        languageItem.submenu = languageMenu
        for language in LocalizationManager.shared.availableLanguages {
            let item = NSMenuItem(title: language.displayName, action: #selector(changeLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = language.code
            languageMenu.addItem(item)
        }
        menu.addItem(languageItem)
        menu.addItem(NSMenuItem.separator())
        let autoStartItem = NSMenuItem(title: LocalizationManager.shared.localizedString("auto_start"), action: #selector(toggleAutoStart), keyEquivalent: "")
        autoStartItem.target = self
        autoStartItem.state = AutoStartManager.shared.isEnabled ? .on : .off
        menu.addItem(autoStartItem)
        let hideFromDockItem = NSMenuItem(title: LocalizationManager.shared.localizedString("hide_from_dock"), action: #selector(toggleHideFromDock), keyEquivalent: "")
        hideFromDockItem.target = self
        hideFromDockItem.state = UserDefaults.standard.bool(forKey: "hideFromDock") ? .on : .off
        menu.addItem(hideFromDockItem)
        menu.addItem(NSMenuItem.separator())
        let aboutItem = NSMenuItem(title: LocalizationManager.shared.localizedString("about"), action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        let quitItem = NSMenuItem(title: LocalizationManager.shared.localizedString("quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        self.statusItem?.menu = menu
        print("✅ Menu created and assigned")
    }

    private func setStatusBarIconToCurrentInputSource() {
        guard let button = statusItem?.button else { return }
        if let current = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() {
            if let urlPtr = TISGetInputSourceProperty(current, kTISPropertyIconImageURL) {
                let cfUrl = unsafeBitCast(urlPtr, to: CFURL.self)
                let url = cfUrl as URL
                if let img = NSImage(contentsOf: url) {
                    img.isTemplate = false
                    button.image = img
                    return
                }
            }
        }
        // Fallback to SF Symbol if icon missing
        button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
    }

    @objc private func updateStatusBarIcon() {
        setStatusBarIconToCurrentInputSource()
    }

    @objc private func changeLanguage(_ sender: NSMenuItem) {
        if let languageCode = sender.representedObject as? String {
            LocalizationManager.shared.setLanguage(languageCode)
            setupStatusBar()
        }
    }

    @objc private func toggleAutoStart() {
        AutoStartManager.shared.toggle()
        setupStatusBar()
    }

    @objc private func toggleHideFromDock() {
        let currentState = UserDefaults.standard.bool(forKey: "hideFromDock")
        UserDefaults.standard.set(!currentState, forKey: "hideFromDock")
        if !currentState {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
        }
        setupStatusBar()
    }

    @objc private func showAbout() {
        AboutWindowController.show()
    }
} 