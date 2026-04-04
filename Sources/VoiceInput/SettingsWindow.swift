import AppKit

final class SettingsWindow: NSObject, NSWindowDelegate, ShortcutRecorderViewDelegate {

    private static let windowWidth: CGFloat = 420
    private static let windowHeight: CGFloat = 400

    private var window: NSWindow!
    private var launchAtLoginCheckbox: NSButton!
    private var enableRefinementCheckbox: NSButton!
    private var apiBaseUrlField: NSTextField!
    private var apiKeyField: NSSecureTextField!
    private var modelField: NSTextField!
    private var shortcutRecorder: ShortcutRecorderView!
    private var onShortcutChanged: ((Shortcut?) -> Void)?

    override init() {
        super.init()
        buildWindow()
    }

    private func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Self.windowWidth, height: Self.windowHeight),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.center()

        window.delegate = self

        setupKeyboardShortcuts()
        buildContent()
    }

    private func buildContent() {
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: Self.windowWidth, height: Self.windowHeight))
        window.contentView = contentView

        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.alignment = .leading
        mainStack.distribution = .fill

        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)
        ])

        let generalLabel = NSTextField(labelWithString: "General")
        generalLabel.font = NSFont.boldSystemFont(ofSize: 13)
        mainStack.addArrangedSubview(generalLabel)

        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(launchAtLoginToggled))
        launchAtLoginCheckbox.state = LaunchAtLoginManager.isEnabled ? .on : .off
        mainStack.addArrangedSubview(launchAtLoginCheckbox)

        let separator1 = NSBox()
        separator1.boxType = .separator
        separator1.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(separator1)
        NSLayoutConstraint.activate([
            separator1.widthAnchor.constraint(equalToConstant: 380)
        ])

        let shortcutLabel = NSTextField(labelWithString: "Keyboard Shortcut")
        shortcutLabel.font = NSFont.boldSystemFont(ofSize: 13)
        mainStack.addArrangedSubview(shortcutLabel)

        let shortcutRow = NSStackView()
        shortcutRow.orientation = .horizontal
        shortcutRow.spacing = 8
        shortcutRow.alignment = .centerY
        shortcutRow.distribution = .fill
        mainStack.addArrangedSubview(shortcutRow)

        shortcutRecorder = ShortcutRecorderView()
        shortcutRecorder.delegate = self
        shortcutRow.addArrangedSubview(shortcutRecorder)

        let resetButton = NSButton(title: "Reset to Default", target: self, action: #selector(resetShortcutToDefault))
        resetButton.bezelStyle = .rounded
        shortcutRow.addArrangedSubview(resetButton)

        let separator2 = NSBox()
        separator2.boxType = .separator
        separator2.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(separator2)
        NSLayoutConstraint.activate([
            separator2.widthAnchor.constraint(equalToConstant: 380)
        ])

        let llmLabel = NSTextField(labelWithString: "LLM Refinement")
        llmLabel.font = NSFont.boldSystemFont(ofSize: 13)
        mainStack.addArrangedSubview(llmLabel)

        enableRefinementCheckbox = NSButton(checkboxWithTitle: "Enable LLM Refinement", target: self, action: #selector(enableRefinementToggled))
        enableRefinementCheckbox.state = LLMRefiner.isEnabled ? .on : .off
        mainStack.addArrangedSubview(enableRefinementCheckbox)

        let formStack = NSStackView()
        formStack.orientation = .vertical
        formStack.spacing = 8
        formStack.alignment = .leading
        formStack.distribution = .fill
        mainStack.addArrangedSubview(formStack)

        let apiBaseUrlRow = createFormRow(label: "API Base URL", placeholder: "https://api.openai.com", defaultValue: LLMRefiner.apiBaseUrl, isSecure: false)
        apiBaseUrlField = apiBaseUrlRow.field
        formStack.addArrangedSubview(apiBaseUrlRow.view)

        let apiKeyRow = createFormRow(label: "API Key", placeholder: "sk-...", defaultValue: LLMRefiner.apiKey, isSecure: true)
        apiKeyField = apiKeyRow.secureField!
        formStack.addArrangedSubview(apiKeyRow.view)

        let modelRow = createFormRow(label: "Model", placeholder: "gpt-4o-mini", defaultValue: LLMRefiner.model, isSecure: false)
        modelField = modelRow.field
        formStack.addArrangedSubview(modelRow.view)

        NSLayoutConstraint.activate([
            apiBaseUrlRow.field.widthAnchor.constraint(equalToConstant: 320),
            apiKeyRow.field.widthAnchor.constraint(equalToConstant: 320),
            modelRow.field.widthAnchor.constraint(equalToConstant: 320),
        ])

        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8
        buttonStack.distribution = .fill
        mainStack.addArrangedSubview(buttonStack)

        let testButton = NSButton(title: "Test", target: self, action: #selector(testConnection))
        testButton.bezelStyle = .rounded

        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveSettings))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"

        buttonStack.addArrangedSubview(testButton)
        buttonStack.addArrangedSubview(saveButton)
    }

    private func createFormRow(label: String, placeholder: String, defaultValue: String, isSecure: Bool) -> (view: NSView, field: NSTextField, secureField: NSSecureTextField?) {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let labelView = NSTextField(labelWithString: label)
        labelView.font = NSFont.systemFont(ofSize: 12)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(labelView)

        let field: NSTextField
        var secureField: NSSecureTextField? = nil
        
        if isSecure {
            let sf = NSSecureTextField()
            sf.placeholderString = placeholder
            sf.stringValue = defaultValue
            sf.translatesAutoresizingMaskIntoConstraints = false
            sf.focusRingType = .exterior
            field = sf
            secureField = sf
        } else {
            field = NSTextField()
            field.placeholderString = placeholder
            field.stringValue = defaultValue
            field.translatesAutoresizingMaskIntoConstraints = false
            field.focusRingType = .exterior
        }
        container.addSubview(field)

        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: container.topAnchor),
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            field.topAnchor.constraint(equalTo: labelView.bottomAnchor, constant: 4),
            field.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            field.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            container.widthAnchor.constraint(equalToConstant: 320),
        ])

        return (container, field, secureField)
    }

    @objc private func launchAtLoginToggled() {
        let isEnabled = launchAtLoginCheckbox.state == .on
        if isEnabled {
            try? LaunchAtLoginManager.register()
        } else {
            LaunchAtLoginManager.unregister()
        }
    }

    @objc private func enableRefinementToggled() {
        LLMRefiner.isEnabled = enableRefinementCheckbox.state == .on
    }

    @objc private func testConnection() {
        let baseURL = apiBaseUrlField.stringValue
        let apiKey = apiKeyField.stringValue
        let model = modelField.stringValue

        if baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showAlert(title: "Validation Error", message: "API Base URL cannot be empty.")
            return
        }
        if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showAlert(title: "Validation Error", message: "API Key cannot be empty.")
            return
        }

        let savedBaseURL = LLMRefiner.apiBaseUrl
        let savedKey = LLMRefiner.apiKey
        let savedModel = LLMRefiner.model
        LLMRefiner.apiBaseUrl = baseURL
        LLMRefiner.apiKey = apiKey
        LLMRefiner.model = model

        Task {
            do {
                let response = try await LLMRefiner.testConnection()
                LLMRefiner.apiBaseUrl = savedBaseURL
                LLMRefiner.apiKey = savedKey
                LLMRefiner.model = savedModel

                await MainActor.run {
                    let snippet = String(response.prefix(200))
                    showAlert(
                        title: "Connection Successful",
                        message: "Server responded:\n\n\(snippet)"
                    )
                }
            } catch {
                LLMRefiner.apiBaseUrl = savedBaseURL
                LLMRefiner.apiKey = savedKey
                LLMRefiner.model = savedModel

                await MainActor.run {
                    showAlert(title: "Connection Failed", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func saveSettings() {
        LLMRefiner.apiBaseUrl = apiBaseUrlField.stringValue
        LLMRefiner.apiKey = apiKeyField.stringValue
        LLMRefiner.model = modelField.stringValue
        LLMRefiner.isEnabled = enableRefinementCheckbox.state == .on

        showAlert(title: "Saved", message: "Settings have been saved successfully.") { [weak self] in
            self?.window.close()
        }
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        if let window = window {
            alert.beginSheetModal(for: window) { _ in
                completion?()
            }
        } else {
            completion?()
        }
    }

    func show() {
        launchAtLoginCheckbox.state = LaunchAtLoginManager.isEnabled ? .on : .off
        enableRefinementCheckbox.state = LLMRefiner.isEnabled ? .on : .off
        apiBaseUrlField.stringValue = LLMRefiner.apiBaseUrl
        apiKeyField.stringValue = LLMRefiner.apiKey
        modelField.stringValue = LLMRefiner.model
        shortcutRecorder.setShortcut(ShortcutManager.shared.currentShortcut)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            let isCommandPressed = event.modifierFlags.contains(.command)
            let keyCode = event.keyCode

            if isCommandPressed {
                switch keyCode {
                case 8:
                    self.copy(nil)
                    return nil
                case 9:
                    self.paste(nil)
                    return nil
                case 7:
                    self.cut(nil)
                    return nil
                case 0:
                    self.selectAll(nil)
                    return nil
                default:
                    break
                }
            }
            return event
        }
    }

    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        let selector = item.action
        let responder = window.firstResponder
        let isEditingAction = selector == #selector(copy(_:)) ||
                              selector == #selector(paste(_:)) ||
                              selector == #selector(cut(_:)) ||
                              selector == #selector(selectAll(_:))
        return isEditingAction && responder is NSTextField
    }

    @objc func copy(_ sender: Any?) {
        window.firstResponder?.tryToPerform(#selector(copy(_:)), with: sender)
    }

    @objc func paste(_ sender: Any?) {
        window.firstResponder?.tryToPerform(#selector(paste(_:)), with: sender)
    }

    @objc func cut(_ sender: Any?) {
        window.firstResponder?.tryToPerform(#selector(cut(_:)), with: sender)
    }

    @objc func selectAll(_ sender: Any?) {
        window.firstResponder?.tryToPerform(#selector(selectAll(_:)), with: sender)
    }

    func setOnShortcutChanged(_ callback: @escaping (Shortcut?) -> Void) {
        onShortcutChanged = callback
    }

    func shortcutRecorderView(_ view: ShortcutRecorderView, didCaptureShortcut shortcut: Shortcut) {
        ShortcutManager.shared.saveShortcut(shortcut)
        onShortcutChanged?(shortcut)
    }

    func shortcutRecorderViewDidCancelRecording(_ view: ShortcutRecorderView) {
    }

    @objc private func resetShortcutToDefault() {
        ShortcutManager.shared.resetToDefault()
        shortcutRecorder.setShortcut(nil)
        onShortcutChanged?(nil)
    }
}
