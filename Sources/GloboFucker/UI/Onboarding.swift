import Cocoa
import Carbon

private final class OnboardingWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Lightweight, glass-styled onboarding wizard.
/// Steps: welcome → globe setup → accessibility permission.
final class OnboardingWindowController: NSWindowController {
    private let pageController = NSPageController()
    private let primaryButton = NSButton(title: "", target: nil, action: nil)
    private let titleLabel = NSTextField(labelWithString: "GloboFucker")
    private let closeButton = NSButton()
    private var pages: [String] = ["welcome", "globe", "perm"]
    private var currentIndex: Int = 0 { didSet { updateButtons() } }

    convenience init() {
        let window = OnboardingWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 560),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        self.init(window: window)
        window.delegate = self
        setup()
        window.makeKeyAndOrderFront(nil)
    }

    /// Builds the window content and embeds `NSPageController`
    private func setup() {
        guard let window = window else { return }
        let root = NSView()
        root.wantsLayer = true
        root.layer?.cornerRadius = 16
        root.layer?.masksToBounds = true
        // Fill window content; use autoresizing to avoid zero-size when added as contentView
        root.translatesAutoresizingMaskIntoConstraints = true
        root.autoresizingMask = [.width, .height]
        root.frame = window.contentLayoutRect

        let blur = NSVisualEffectView()
        blur.material = .hudWindow
        blur.state = .active
        blur.blendingMode = .withinWindow
        blur.translatesAutoresizingMaskIntoConstraints = false

        let header = NSView()
        header.translatesAutoresizingMaskIntoConstraints = false
        let headerHeight: CGFloat = 48

        // Custom close button
        closeButton.title = ""
        closeButton.target = self
        closeButton.action = #selector(onClose)
        closeButton.bezelStyle = .regularSquare
        closeButton.isBordered = false
        closeButton.wantsLayer = true
        closeButton.layer?.backgroundColor = NSColor.systemRed.cgColor
        closeButton.layer?.cornerRadius = 7
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setButtonType(.momentaryPushIn)

        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.alignment = .center
        titleLabel.textColor = .labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.isHidden = true

        header.addSubview(titleLabel)
        header.addSubview(closeButton)

        let pageContainer = NSView()
        pageContainer.translatesAutoresizingMaskIntoConstraints = false

        let footer = NSView()
        footer.translatesAutoresizingMaskIntoConstraints = false

        // Primary centered button
        primaryButton.bezelStyle = .rounded
        primaryButton.target = self
        primaryButton.action = #selector(goNext)
        primaryButton.setButtonType(.momentaryPushIn)
        primaryButton.isEnabled = true
        primaryButton.wantsLayer = true
        primaryButton.layer?.cornerRadius = 8
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.keyEquivalent = "\r"
        footer.addSubview(primaryButton)

        // Assemble
        root.addSubview(blur)
        root.addSubview(header)
        root.addSubview(pageContainer)
        root.addSubview(footer)

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: root.topAnchor),
            blur.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: root.trailingAnchor),

            header.topAnchor.constraint(equalTo: root.topAnchor),
            header.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: headerHeight),

            closeButton.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 14),
            closeButton.heightAnchor.constraint(equalToConstant: 14),

            titleLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            footer.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -20),
            footer.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            footer.heightAnchor.constraint(equalToConstant: 44),
            footer.widthAnchor.constraint(greaterThanOrEqualToConstant: 160),

            primaryButton.centerXAnchor.constraint(equalTo: footer.centerXAnchor),
            primaryButton.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
            primaryButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 160),

            pageContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 20),
            pageContainer.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 40),
            pageContainer.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -40),
            pageContainer.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -8)
        ])

        // Embed page controller view (use existing controller view, do not replace it)
        pageController.view.translatesAutoresizingMaskIntoConstraints = false
        pageController.transitionStyle = .horizontalStrip
        pageController.delegate = self
        pageController.arrangedObjects = pages
        pageContainer.addSubview(pageController.view)
        NSLayoutConstraint.activate([
            pageController.view.topAnchor.constraint(equalTo: pageContainer.topAnchor),
            pageController.view.bottomAnchor.constraint(equalTo: pageContainer.bottomAnchor),
            pageController.view.leadingAnchor.constraint(equalTo: pageContainer.leadingAnchor),
            pageController.view.trailingAnchor.constraint(equalTo: pageContainer.trailingAnchor)
        ])

        // Attach a host view controller and add page controller as child for proper lifecycle
        let hostVC = NSViewController()
        hostVC.view = root
        self.contentViewController = hostVC
        hostVC.addChild(pageController)
        // Ensure window uses our root view sizing
        window.contentView = root
        window.setContentSize(NSSize(width: 820, height: 560))
        
        pageController.selectedIndex = 0
        updateButtons()
    }

    /// Updates the primary button title depending on the current page
    private func updateButtons() {
        let title: String
        if currentIndex < pages.count - 1 {
            title = LocalizationManager.shared.localizedString("ob_next")
        } else {
            title = LocalizationManager.shared.localizedString("ob_finish")
        }
        primaryButton.title = title
    }

    /// Advances to the next page or finishes the onboarding
    @objc private func goNext() {
        guard let window = self.window else { return }
        print("Onboarding goNext pressed; index=\(currentIndex)")
        window.makeFirstResponder(nil)
        if currentIndex < pages.count - 1 {
            currentIndex += 1
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.pageController.selectedIndex = self.currentIndex
                self.pageController.navigateForward(nil)
            }
        } else {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
            self.close()
        }
    }

    /// Close handler: quits app if onboarding not completed yet
    @objc private func onClose() {
        print("Onboarding close pressed")
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            NSApp.terminate(nil)
        } else {
            self.close()
        }
    }
}

extension OnboardingWindowController: NSPageControllerDelegate, NSWindowDelegate {
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        switch identifier {
        case "welcome":
            return OnboardingWelcomeVC()
        case "globe":
            return OnboardingGlobeVC()
        default:
            return OnboardingPermissionVC()
        }
    }

    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> String {
        if let s = object as? String { return s }
        if let index = object as? Int { return ["welcome", "globe", "perm"][max(0, min(2, index))] }
        return "welcome"
    }

    func windowWillClose(_ notification: Notification) {
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            NSApp.terminate(nil)
        }
    }
}

// MARK: - Pages

private final class OnboardingWelcomeVC: NSViewController {
    override func loadView() {
        let v = buildContainer()
        let title = makeTitle(LocalizationManager.shared.localizedString("ob_welcome_title"))
        let subtitle = makeSubtitle(LocalizationManager.shared.localizedString("ob_welcome_subtitle"))
        v.stack.addArrangedSubview(title)
        v.stack.addArrangedSubview(subtitle)
        self.view = v.root
    }
}

private final class OnboardingGlobeVC: NSViewController {
    private let result = NSTextField(labelWithString: "")
    override func loadView() {
        let v = buildContainer()
        let title = makeTitle(LocalizationManager.shared.localizedString("ob_globe_title"))
        let subtitle = makeSubtitle(LocalizationManager.shared.localizedString("ob_globe_subtitle"))
        let openBtn = NSButton(title: LocalizationManager.shared.localizedString("open_keyboard_settings"), target: self, action: #selector(openSettings))
        openBtn.bezelStyle = .rounded
        let testBtn = NSButton(title: LocalizationManager.shared.localizedString("test_globe"), target: self, action: #selector(testGlobe))
        testBtn.bezelStyle = .rounded
        let btns = NSStackView(views: [openBtn, testBtn])
        btns.spacing = 8
        btns.alignment = .centerY
        btns.orientation = .horizontal
        result.font = .systemFont(ofSize: 12)
        result.alignment = .center
        result.textColor = .tertiaryLabelColor
        v.stack.addArrangedSubview(title)
        v.stack.addArrangedSubview(subtitle)
        v.stack.addArrangedSubview(btns)
        v.stack.addArrangedSubview(result)
        self.view = v.root
    }
    @objc private func openSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.keyboard")!)
    }
    @objc private func testGlobe() {
        result.stringValue = LocalizationManager.shared.localizedString("test_waiting")
        result.textColor = .secondaryLabelColor
        var changed = false
        let center = DistributedNotificationCenter.default()
        let name = Notification.Name(rawValue: kTISNotifySelectedKeyboardInputSourceChanged as String)
        let obs = center.addObserver(forName: name, object: nil, queue: .main) { _ in changed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            center.removeObserver(obs)
            if changed {
                self.result.stringValue = LocalizationManager.shared.localizedString("test_failed")
                self.result.textColor = .systemRed
            } else {
                self.result.stringValue = LocalizationManager.shared.localizedString("test_passed")
                self.result.textColor = .systemGreen
            }
        }
    }
}

private final class OnboardingPermissionVC: NSViewController {
    override func loadView() {
        let v = buildContainer()
        let title = makeTitle(LocalizationManager.shared.localizedString("ob_perm_title"))
        let subtitle = makeSubtitle(LocalizationManager.shared.localizedString("accessibility_permission_message"))
        let grant = NSButton(title: LocalizationManager.shared.localizedString("grant_permission"), target: self, action: #selector(grantPerm))
        grant.bezelStyle = .rounded
        v.stack.addArrangedSubview(title)
        v.stack.addArrangedSubview(subtitle)
        v.stack.addArrangedSubview(grant)
        self.view = v.root
    }
    @objc private func grantPerm() {
        let opts: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(opts)
    }
}

// MARK: - UI Helpers

private func buildContainer() -> (root: NSView, stack: NSStackView) {
    let root = NSView()
    let stack = NSStackView()
    stack.orientation = .vertical
    stack.alignment = .centerX
    stack.spacing = 10
    stack.edgeInsets = NSEdgeInsets(top: 30, left: 40, bottom: 30, right: 40)
    stack.translatesAutoresizingMaskIntoConstraints = false
    root.addSubview(stack)
    NSLayoutConstraint.activate([
        stack.topAnchor.constraint(equalTo: root.topAnchor),
        stack.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
        stack.trailingAnchor.constraint(equalTo: root.trailingAnchor)
    ])
    return (root, stack)
}

private func makeTitle(_ text: String) -> NSTextField {
    let t = NSTextField(labelWithString: text)
    t.font = .systemFont(ofSize: 22, weight: .semibold)
    t.alignment = .center
    return t
}

private func makeSubtitle(_ text: String) -> NSTextField {
    let s = NSTextField(wrappingLabelWithString: text)
    s.font = .systemFont(ofSize: 13)
    s.alignment = .center
    s.textColor = .secondaryLabelColor
    return s
}

