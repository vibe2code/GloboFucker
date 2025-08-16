import Cocoa

/// Simple “About” window with blur background and localized content
class AboutWindowController: NSWindowController {
    private static var sharedInstance: AboutWindowController?

    static func show() {
        if let existing = sharedInstance {
            existing.showWindow(nil)
            existing.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let contentRect = NSRect(x: 0, y: 0, width: 640, height: 420)
        let window = NSWindow(contentRect: contentRect, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = LocalizationManager.shared.localizedString("about")
        window.isOpaque = true
        window.backgroundColor = .windowBackgroundColor
        window.hasShadow = true
        window.titlebarAppearsTransparent = false
        window.center()

        let controller = AboutWindowController(window: window)
        controller.window?.contentViewController = AboutContentViewController()
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        sharedInstance = controller
    }
}

private final class AboutContentViewController: NSViewController {
    override func loadView() {
        let container = NSView()
        container.wantsLayer = true

        let blur = NSVisualEffectView()
        blur.translatesAutoresizingMaskIntoConstraints = false
        blur.material = .hudWindow
        blur.state = .active
        blur.blendingMode = .behindWindow
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 16
        blur.layer?.masksToBounds = true

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false

        // App icon
        let icon = NSImageView()
        icon.image = NSApp.applicationIconImage
        icon.symbolConfiguration = .init(pointSize: 64, weight: .regular)
        icon.imageScaling = .scaleProportionallyUpOrDown

        // Title and version
        let title = NSTextField(labelWithString: "GloboFucker")
        title.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        title.textColor = .labelColor

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let subtitle = NSTextField(labelWithString: "v\(version)")
        subtitle.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        subtitle.textColor = .secondaryLabelColor

        // Body text
        let aboutTemplate = LocalizationManager.shared.localizedString("about_text")
        let about = NSTextField(wrappingLabelWithString: aboutTemplate.replacingOccurrences(of: "{version}", with: version))
        about.alignment = .center
        about.font = NSFont.systemFont(ofSize: 13)
        about.textColor = .labelColor

        let authorLabel = LocalizationManager.shared.localizedString("lang_author_label")
        let author = LocalizationManager.shared.localizedString("lang_author")
        let footer = NSTextField(labelWithString: "Made with ❤️ by PINGVI  •  \(authorLabel) \(author)")
        footer.font = NSFont.systemFont(ofSize: 12)
        footer.textColor = .tertiaryLabelColor

        // OK button
        let ok = NSButton(title: LocalizationManager.shared.localizedString("ok"), target: self, action: #selector(closeWindow))
        ok.bezelStyle = .rounded

        let h1 = NSStackView(views: [icon])
        h1.alignment = .centerX
        let h2 = NSStackView(views: [title, subtitle])
        h2.orientation = .vertical
        h2.alignment = .centerX
        h2.spacing = 2

        stack.addArrangedSubview(h1)
        stack.addArrangedSubview(h2)
        stack.addArrangedSubview(about)
        stack.addArrangedSubview(footer)
        stack.addArrangedSubview(ok)

        container.addSubview(blur)
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: container.topAnchor),
            blur.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        self.view = container
    }

    @objc private func closeWindow() {
        view.window?.close()
    }
}