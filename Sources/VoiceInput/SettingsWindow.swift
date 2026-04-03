import AppKit

final class SettingsWindow: NSObject, NSWindowDelegate {

    private var window: NSWindow!
    private var apiBaseUrlField: NSTextField!
    private var apiKeyField: NSSecureTextField!
    private var modelField: NSTextField!

    override init() {
        super.init()
        buildWindow()
    }

    private func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 280),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "LLM Refinement Settings"
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.center()

        window.delegate = self

        setupKeyboardShortcuts()

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = contentView

        let formStack = NSStackView()
        formStack.orientation = .vertical
        formStack.spacing = 12
        formStack.translatesAutoresizingMaskIntoConstraints = false
        formStack.alignment = .leading
        formStack.distribution = .fill

        formStack.addArrangedSubview(makeTextFieldGroup(
            label: "API Base URL",
            placeholder: "https://api.example.com",
            defaultValue: LLMRefiner.apiBaseUrl,
            secure: false
        ))

        formStack.addArrangedSubview(makeSecureFieldGroup(
            label: "API Key",
            placeholder: "sk-...",
            defaultValue: LLMRefiner.apiKey
        ))

        formStack.addArrangedSubview(makeTextFieldGroup(
            label: "Model",
            placeholder: "gpt-4o",
            defaultValue: LLMRefiner.model,
            secure: false
        ))

        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.alignment = .centerY
        buttonStack.distribution = .fillProportionally

        let testButton = NSButton(title: "Test", target: self, action: #selector(testConnection))
        testButton.bezelStyle = .rounded

        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveSettings))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"

        buttonStack.addArrangedSubview(testButton)
        buttonStack.addArrangedSubview(saveButton)

        contentView.addSubview(formStack)
        contentView.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            formStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            formStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            formStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            buttonStack.topAnchor.constraint(equalTo: formStack.bottomAnchor, constant: 20),
            buttonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            buttonStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])
    }

    private func makeTextFieldGroup(label text: String, placeholder: String, defaultValue: String, secure: Bool) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.spacing = 4
        container.alignment = .leading
        container.distribution = .fill

        let label = NSTextField(labelWithString: text)
        label.font = NSFont.boldSystemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false

        let field = NSTextField()
        field.placeholderString = placeholder
        field.stringValue = defaultValue
        field.translatesAutoresizingMaskIntoConstraints = false
        field.focusRingType = .exterior

        if text == "API Base URL" {
            apiBaseUrlField = field
        } else if text == "Model" {
            modelField = field
        }

        container.addArrangedSubview(label)
        container.addArrangedSubview(field)

        NSLayoutConstraint.activate([
            field.widthAnchor.constraint(equalTo: container.widthAnchor)
        ])

        return container
    }

    private func makeSecureFieldGroup(label text: String, placeholder: String, defaultValue: String) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.spacing = 4
        container.alignment = .leading
        container.distribution = .fill

        let label = NSTextField(labelWithString: text)
        label.font = NSFont.boldSystemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false

        let field = NSSecureTextField()
        field.placeholderString = placeholder
        field.stringValue = defaultValue
        field.translatesAutoresizingMaskIntoConstraints = false
        field.focusRingType = .exterior

        apiKeyField = field

        container.addArrangedSubview(label)
        container.addArrangedSubview(field)

        NSLayoutConstraint.activate([
            field.widthAnchor.constraint(equalTo: container.widthAnchor)
        ])

        return container
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
        let baseURL = apiBaseUrlField.stringValue
        let apiKey = apiKeyField.stringValue
        let model = modelField.stringValue

        LLMRefiner.apiBaseUrl = baseURL
        LLMRefiner.apiKey = apiKey
        LLMRefiner.model = model

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
        alert.beginSheetModal(for: window) { _ in
            completion?()
        }
    }

    func show() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            let isCommandPressed = event.modifierFlags.contains(.command)
            let keyCode = event.keyCode
            
            // Key codes: C=8, V=9, X=7, A=0
            if isCommandPressed {
                switch keyCode {
                case 8: // Cmd+C
                    Logger.settings.debug("Cmd+C captured")
                    self.copy(nil)
                    return nil
                case 9: // Cmd+V
                    Logger.settings.debug("Cmd+V captured")
                    self.paste(nil)
                    return nil
                case 7: // Cmd+X
                    Logger.settings.debug("Cmd+X captured")
                    self.cut(nil)
                    return nil
                case 0: // Cmd+A
                    Logger.settings.debug("Cmd+A captured")
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
        Logger.settings.debug("validateUserInterfaceItem called: \(String(describing: selector)), firstResponder: \(String(describing: type(of: responder)))")
        let isEditingAction = selector == #selector(copy(_:)) ||
                              selector == #selector(paste(_:)) ||
                              selector == #selector(cut(_:)) ||
                              selector == #selector(selectAll(_:))
        let result = isEditingAction && responder is NSTextField
        Logger.settings.debug("validateUserInterfaceItem result: \(result)")
        return result
    }

    @objc func copy(_ sender: Any?) {
        Logger.settings.debug("copy action called")
        window.firstResponder?.tryToPerform(#selector(copy(_:)), with: sender)
    }

    @objc func paste(_ sender: Any?) {
        Logger.settings.debug("paste action called")
        window.firstResponder?.tryToPerform(#selector(paste(_:)), with: sender)
    }

    @objc func cut(_ sender: Any?) {
        Logger.settings.debug("cut action called")
        window.firstResponder?.tryToPerform(#selector(cut(_:)), with: sender)
    }

    @objc func selectAll(_ sender: Any?) {
        Logger.settings.debug("selectAll action called")
        window.firstResponder?.tryToPerform(#selector(selectAll(_:)), with: sender)
    }
}
