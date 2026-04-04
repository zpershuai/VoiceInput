import AppKit
import Foundation

struct PermissionAlertContent {
    let title: String
    let message: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String
}

final class PermissionAlert: NSObject, NSWindowDelegate {
    private static let systemSettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )!

    private let onPermissionGranted: () -> Void

    private var alertWindow: NSWindow?
    private var pollingTimer: Timer?
    private var isDismissing = false

    init(onPermissionGranted: @escaping () -> Void) {
        self.onPermissionGranted = onPermissionGranted
    }

    func showAccessibilityPermissionAlert() {
        let content = Self.localizedContent(for: LanguageManager.shared.currentLanguage)
        let window = makeWindow(content: content)

        alertWindow = window
        startPolling()

        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.runModal(for: window)
    }

    static func localizedContent(for languageCode: String) -> PermissionAlertContent {
        if languageCode.hasPrefix("zh") {
            return PermissionAlertContent(
                title: "需要辅助功能权限",
                message: "VoiceInput 需要辅助功能权限来监听 Fn 键并启用全局语音输入。请在系统设置中允许此应用，然后返回此窗口。",
                primaryButtonTitle: "打开系统设置",
                secondaryButtonTitle: "退出"
            )
        }

        return PermissionAlertContent(
            title: "Accessibility Permission Required",
            message: "VoiceInput needs Accessibility permission to monitor the Fn key and enable global voice input. Allow this app in System Settings, then return to this window.",
            primaryButtonTitle: "Open System Settings",
            secondaryButtonTitle: "Quit"
        )
    }

    func windowWillClose(_ notification: Notification) {
        stopPolling()
        completeDismissal()
    }

    // MARK: - Actions

    @objc private func openSystemSettings() {
        Logger.app.info("User initiated opening System Settings from permission dialog")
        GlobalEventMonitor.openSystemSettingsAccessibility()
    }

    @objc private func quitApplication() {
        stopPolling()
        completeDismissal()
        NSApplication.shared.terminate(nil)
    }

    @objc private func checkPermissionStatus() {
        guard GlobalEventMonitor.checkAccessibilityPermission() else {
            return
        }

        Logger.app.info("Accessibility permission granted while permission dialog was visible")
        stopPolling()
        completeDismissal()
        onPermissionGranted()
    }

    // MARK: - Private

    private func startPolling() {
        stopPolling()

        pollingTimer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(checkPermissionStatus),
            userInfo: nil,
            repeats: true
        )
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private func completeDismissal() {
        guard !isDismissing else {
            return
        }

        isDismissing = true

        if let alertWindow, NSApp.modalWindow == alertWindow {
            NSApp.stopModal()
        }

        if let alertWindow {
            alertWindow.orderOut(nil)
        }

        alertWindow = nil
        isDismissing = false
    }

    private func makeWindow(content: PermissionAlertContent) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 220),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )

        window.title = content.title
        window.isReleasedWhenClosed = false
        window.level = .modalPanel
        window.delegate = self
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = contentView

        let titleLabel = NSTextField(labelWithString: content.title)
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let messageLabel = NSTextField(wrappingLabelWithString: content.message)
        messageLabel.alignment = .center
        messageLabel.maximumNumberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        let openButton = NSButton(title: content.primaryButtonTitle, target: self, action: #selector(openSystemSettings))
        openButton.bezelStyle = .rounded
        openButton.translatesAutoresizingMaskIntoConstraints = false

        let quitButton = NSButton(title: content.secondaryButtonTitle, target: self, action: #selector(quitApplication))
        quitButton.bezelStyle = .rounded
        quitButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(openButton)
        contentView.addSubview(quitButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            openButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            openButton.trailingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -8),
            openButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            quitButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            quitButton.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 8),
            quitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        return window
    }
}
