import AVFoundation
import AppKit
import Combine
import Foundation
import Speech

class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    private var statusItem: NSStatusItem!
    private var eventMonitor: GlobalEventMonitor!
    private var speechRecognizer: SpeechRecognizer!
    private var floatingWindow: FloatingWindow!
    private var settingsWindow: SettingsWindow!
    private var permissionAlert: PermissionAlert?
    private var isRecording: Bool = false
    private var isEventMonitorRunning: Bool = false

    private var cancellables = Set<AnyCancellable>()

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.app.info("Application launching...")
        
        // Clean old logs
        Logger.shared.clearOldLogs(keepingDays: 7)
        
        // 1. Set up the menu bar status item
        setupStatusBar()
        
        // 2. Build the menu bar menu
        buildMenuBar()
        
        // 3. Initialize all components
        eventMonitor = GlobalEventMonitor()
        speechRecognizer = SpeechRecognizer(localeCode: LanguageManager.shared.currentLanguage)
        floatingWindow = FloatingWindow()
        settingsWindow = SettingsWindow()
        
        applyStoredShortcut()
        
        settingsWindow.setOnShortcutChanged { [weak self] _ in
            self?.applyStoredShortcut()
        }
        
        Logger.app.info("Components initialized - Language: \(LanguageManager.shared.currentLanguage)")
        
        // 4. Synchronize launch-at-login state
        LaunchAtLoginManager.synchronizeState()
        
        // 4. Connect callbacks
        eventMonitor.onStartRecording = { [weak self] in
            Logger.event.debug("Fn key pressed - starting recording")
            self?.startRecording()
        }
        
        eventMonitor.onStopRecording = { [weak self] in
            Logger.event.debug("Fn key released - stopping recording")
            self?.stopRecordingAndInject()
        }
        
        speechRecognizer.onPartialResult = { [weak self] text in
            Logger.speech.debug("Partial result: \(text)")
            self?.floatingWindow.updateText(text)
        }
        
        speechRecognizer.onRMSUpdate = { [weak self] rms in
            self?.floatingWindow.waveform.updateRMS(rms)
        }
        
        speechRecognizer.onFinalResult = { [weak self] text in
            guard let self else { return }
            Logger.speech.info("Final result: \(text)")
            self.floatingWindow.updateText(text)
        }
        
        speechRecognizer.onError = { [weak self] error in
            guard let self else { return }
            Logger.speech.error("SpeechRecognizer error: \(error.localizedDescription)")
            self.floatingWindow.hide()
            self.isRecording = false
        }
        
        // 5. Observe language changes
        LanguageManager.shared.$currentLanguage
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newLanguage in
                Logger.settings.info("Language changed to: \(newLanguage)")
                self?.speechRecognizer.setLanguage(newLanguage)
            }
            .store(in: &cancellables)

        // 6. Check accessibility permission before starting the event monitor
        handleAccessibilityPermissionAtLaunch()
        
        Logger.app.info("Application launched successfully")
        Logger.app.info("Log file: \(Logger.shared.getLogFilePath())")
    }

    // MARK: - Status Bar Setup

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let icon = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Voice Input")
            icon?.isTemplate = true
            button.image = icon
        }
    }

    // MARK: - Menu Bar

    private func buildMenuBar() {
        let menu = NSMenu(title: "VoiceInput")

        // Title item
        let titleItem = NSMenuItem(title: "VoiceInput", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        // Language submenu
        let languageMenu = buildLanguageMenu()
        let languageItem = NSMenuItem(title: "Language", action: nil, keyEquivalent: "")
        languageItem.submenu = languageMenu
        menu.addItem(languageItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit VoiceInput", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func buildLanguageMenu() -> NSMenu {
        let menu = NSMenu(title: "Language")

        let languages = LanguageManager.availableLanguages

        for language in languages {
            let item = NSMenuItem(
                title: language.name,
                action: #selector(languageSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = language.code
            item.state = (language.code == LanguageManager.shared.currentLanguage) ? .on : .off
            menu.addItem(item)
        }

        return menu
    }

    @objc private func languageSelected(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }

        LanguageManager.shared.setLanguage(code)

        // Update menu checkmarks
        guard let languageMenu = sender.menu else { return }
        for item in languageMenu.items {
            if let itemCode = item.representedObject as? String {
                item.state = (itemCode == code) ? .on : .off
            }
        }

        // Update speech recognizer
        speechRecognizer.setLanguage(code)
    }

    @objc private func openSettings() {
        settingsWindow.show()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Recording

    private func handleAccessibilityPermissionAtLaunch() {
        if GlobalEventMonitor.checkAccessibilityPermission() {
            Logger.app.info("Accessibility permission already granted")
            startEventMonitorIfNeeded()
            return
        }

        Logger.app.warning("Accessibility permission missing at launch")
        GlobalEventMonitor.requestAccessibilityPermission()
        presentAccessibilityPermissionAlert()
    }

    private func presentAccessibilityPermissionAlert() {
        permissionAlert = PermissionAlert { [weak self] in
            self?.startEventMonitorIfNeeded()
            self?.permissionAlert = nil
        }

        permissionAlert?.showAccessibilityPermissionAlert()
    }

    private func startEventMonitorIfNeeded() {
        guard !isEventMonitorRunning else {
            return
        }

        eventMonitor.start()
        isEventMonitorRunning = true
        Logger.app.info("Global event monitor started")
    }

    private func startRecording() {
        guard !isRecording else { return }
        
        isRecording = true
        Logger.app.info("Starting recording...")
        Task { @MainActor [weak self] in
            self?.floatingWindow.show()
        }
        
        Task {
            do {
                try await speechRecognizer.startRecording()
                Logger.app.info("Recording started successfully")
            } catch {
                Logger.app.error("Failed to start recording: \(error.localizedDescription)")
                await MainActor.run { [weak self] in
                    self?.floatingWindow.hide()
                    self?.isRecording = false
                }
            }
        }
    }

    private func stopRecordingAndInject() {
        guard isRecording else { return }
        
        isRecording = false
        Logger.app.info("Stopping recording and preparing to inject text")
        
        Task {
            let text = await speechRecognizer.stopRecording()
            
            guard let text, !text.isEmpty else {
                Logger.app.warning("No text captured from speech recognition")
                await MainActor.run {
                    self.floatingWindow.hide()
                }
                return
            }
            
            Logger.app.info("Captured text (\(text.count) chars): \(text.prefix(50))...")
            
            if LLMRefiner.isEnabled, LLMRefiner.isConfigured {
                Logger.llm.info("LLM refinement enabled, sending to API")
                await MainActor.run {
                    self.floatingWindow.updateStatus("Refining...")
                }
                
                do {
                    let refinedText = try await LLMRefiner.refine(text: text)
                    Logger.llm.info("LLM refinement completed")
                    Logger.input.info("Injecting refined text")
                    injectText(refinedText)
                } catch {
                    Logger.llm.error("LLM refinement failed: \(error.localizedDescription)")
                    Logger.input.info("Injecting original text (fallback)")
                    injectText(text)
                }
            } else {
                Logger.input.info("Injecting text directly (LLM disabled)")
                injectText(text)
            }
            
            await MainActor.run {
                self.floatingWindow.hide()
            }
        }
    }

    // MARK: - Text Injection

    private func injectText(_ text: String) {
        TextInjector.inject(text: text) { success in
            if success {
                Logger.input.info("Text injection successful")
            } else {
                Logger.input.error("Text injection failed")
            }
        }
    }

    private func applyStoredShortcut() {
        let shortcut = ShortcutManager.shared.effectiveShortcut
        eventMonitor.updateTargetShortcut(keyCode: shortcut.keyCode, modifierFlags: shortcut.modifierFlags)
        Logger.app.info("Applied shortcut: \(shortcut.displayString)")
    }
}
