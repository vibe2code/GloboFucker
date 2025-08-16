import Cocoa
import Carbon

/// Displays instructions to grant Accessibility permissions
/// and includes a quick keyboard Globe key setup with a test.
class PermissionViewController: NSViewController {
    private let statusLabel = NSTextField(labelWithString: "")
    private let restartButton = NSButton(title: LocalizationManager.shared.localizedString("start"), target: nil, action: nil)
    private let captionLabel = NSTextField(labelWithString: "")
    private let stepsStack = NSStackView()
    private var borderLayer = CALayer()
    private let keyboardTitle = NSTextField(labelWithString: "")
    private let keyboardDesc = NSTextField(wrappingLabelWithString: "")
    private let keyboardButtonsStack = NSStackView()
    private let openKeyboardBtn = NSButton(title: "", target: nil, action: nil)
    private let testGlobeBtn = NSButton(title: "", target: nil, action: nil)
    private let testResult = NSTextField(labelWithString: "")

    override func loadView() {
        let view = NSView()
        view.wantsLayer = true

        // Liquid glass blur effect
        let background = NSView()
        background.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(background)

        // Border stroke
        // remove custom border; rely on system window chrome

        // Header title
        let header = NSTextField(labelWithString: LocalizationManager.shared.localizedString("accessibility_permission"))
        header.alignment = .center
        header.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        header.textColor = .labelColor
        header.translatesAutoresizingMaskIntoConstraints = false

        // Caption
        captionLabel.stringValue = LocalizationManager.shared.localizedString("accessibility_permission_message")
        captionLabel.alignment = .center
        captionLabel.font = NSFont.systemFont(ofSize: 13)
        captionLabel.textColor = .secondaryLabelColor
        captionLabel.translatesAutoresizingMaskIntoConstraints = false

        // Open System Preferences button
        let openButton = NSButton(title: LocalizationManager.shared.localizedString("grant_permission"), target: self, action: #selector(openPreferences))
        openButton.bezelStyle = .rounded
        openButton.translatesAutoresizingMaskIntoConstraints = false

        // Steps list
        stepsStack.orientation = .vertical
        stepsStack.alignment = .leading
        stepsStack.spacing = 6
        stepsStack.translatesAutoresizingMaskIntoConstraints = false
        let steps = [
            LocalizationManager.shared.localizedString("permission_step_1"),
            LocalizationManager.shared.localizedString("permission_step_2"),
            LocalizationManager.shared.localizedString("permission_step_3"),
            LocalizationManager.shared.localizedString("permission_step_4")
        ]
        for s in steps {
            let item = NSTextField(labelWithString: s)
            item.font = NSFont.systemFont(ofSize: 12)
            item.textColor = .secondaryLabelColor
            stepsStack.addArrangedSubview(item)
        }

        // Status label
        statusLabel.alignment = .center
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.textColor = .systemGreen
        statusLabel.backgroundColor = .clear
        statusLabel.isBordered = false
        statusLabel.isEditable = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        // Restart button
        restartButton.target = self
        restartButton.action = #selector(restartApp)
        restartButton.isHidden = true
        restartButton.bezelStyle = .rounded
        restartButton.font = NSFont.systemFont(ofSize: 13)
        restartButton.translatesAutoresizingMaskIntoConstraints = false

        background.addSubview(header)
        background.addSubview(captionLabel)
        background.addSubview(openButton)
        background.addSubview(stepsStack)
        background.addSubview(statusLabel)
        background.addSubview(restartButton)

        // Keyboard setup section
        keyboardTitle.stringValue = LocalizationManager.shared.localizedString("keyboard_setup_title")
        keyboardTitle.alignment = .center
        keyboardTitle.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        keyboardTitle.textColor = .labelColor
        keyboardDesc.stringValue = LocalizationManager.shared.localizedString("keyboard_setup_desc")
        keyboardDesc.alignment = .center
        keyboardDesc.font = NSFont.systemFont(ofSize: 12)
        keyboardDesc.textColor = .secondaryLabelColor
        openKeyboardBtn.title = LocalizationManager.shared.localizedString("open_keyboard_settings")
        openKeyboardBtn.target = self
        openKeyboardBtn.action = #selector(openKeyboardSettings)
        openKeyboardBtn.bezelStyle = .rounded
        testGlobeBtn.title = LocalizationManager.shared.localizedString("test_globe")
        testGlobeBtn.target = self
        testGlobeBtn.action = #selector(runGlobeTest)
        testGlobeBtn.bezelStyle = .rounded
        keyboardButtonsStack.orientation = .horizontal
        keyboardButtonsStack.alignment = .centerY
        keyboardButtonsStack.spacing = 8
        keyboardButtonsStack.addArrangedSubview(openKeyboardBtn)
        keyboardButtonsStack.addArrangedSubview(testGlobeBtn)
        keyboardButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        testResult.stringValue = ""
        testResult.alignment = .center
        testResult.font = NSFont.systemFont(ofSize: 12)
        testResult.textColor = .tertiaryLabelColor
        testResult.translatesAutoresizingMaskIntoConstraints = false

        background.addSubview(keyboardTitle)
        background.addSubview(keyboardDesc)
        background.addSubview(keyboardButtonsStack)
        background.addSubview(testResult)

        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            background.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24),
            background.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            background.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            header.topAnchor.constraint(equalTo: background.topAnchor, constant: 16),
            header.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 24),
            header.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -24),

            captionLabel.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            captionLabel.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 24),
            captionLabel.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -24),

            openButton.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 12),
            openButton.centerXAnchor.constraint(equalTo: background.centerXAnchor),

            stepsStack.topAnchor.constraint(equalTo: openButton.bottomAnchor, constant: 8),
            stepsStack.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 32),
            stepsStack.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -32),

            statusLabel.topAnchor.constraint(equalTo: stepsStack.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -24),

            restartButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            restartButton.centerXAnchor.constraint(equalTo: background.centerXAnchor),
            restartButton.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -16),

            keyboardTitle.topAnchor.constraint(equalTo: restartButton.bottomAnchor, constant: 0),
            keyboardTitle.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 24),
            keyboardTitle.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -24),

            keyboardDesc.topAnchor.constraint(equalTo: keyboardTitle.bottomAnchor, constant: 6),
            keyboardDesc.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 24),
            keyboardDesc.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -24),

            keyboardButtonsStack.topAnchor.constraint(equalTo: keyboardDesc.bottomAnchor, constant: 10),
            keyboardButtonsStack.centerXAnchor.constraint(equalTo: background.centerXAnchor),

            testResult.topAnchor.constraint(equalTo: keyboardButtonsStack.bottomAnchor, constant: 6),
            testResult.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 24),
            testResult.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -24)
        ])

        self.view = view
        updateStatus()
        startPermissionMonitor()
    }

    // no-op: using system window chrome

    @objc func openPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    @objc func openKeyboardSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.keyboard") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func runGlobeTest() {
        testResult.stringValue = LocalizationManager.shared.localizedString("test_waiting")
        testResult.textColor = .secondaryLabelColor

        var changed = false
        let center = DistributedNotificationCenter.default()
        let name = Notification.Name(rawValue: kTISNotifySelectedKeyboardInputSourceChanged as String)
        let obs = center.addObserver(forName: name, object: nil, queue: .main) { _ in
            changed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            center.removeObserver(obs)
            if changed {
                self?.testResult.stringValue = LocalizationManager.shared.localizedString("test_failed")
                self?.testResult.textColor = .systemRed
            } else {
                self?.testResult.stringValue = LocalizationManager.shared.localizedString("test_passed")
                self?.testResult.textColor = .systemGreen
            }
        }
    }

    @objc func restartApp() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [Bundle.main.bundlePath]
        try? task.run()
        NSApp.terminate(nil)
    }

    private func updateStatus() {
        if AXIsProcessTrusted() {
            statusLabel.stringValue = LocalizationManager.shared.localizedString("permission_granted_restart")
            statusLabel.textColor = .systemGreen
            restartButton.isHidden = false
            // Авто-продолжение: сразу запустить приложение без ручного рестарта
            NotificationCenter.default.post(name: .accessibilityPermissionGranted, object: nil)
        } else {
            statusLabel.stringValue = LocalizationManager.shared.localizedString("permission_not_granted")
            statusLabel.textColor = .systemRed
            restartButton.isHidden = true
        }
    }

    private func startPermissionMonitor() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }
} 