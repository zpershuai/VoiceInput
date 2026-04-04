import ApplicationServices
import AppKit
import CoreGraphics
import Foundation

final class GlobalEventMonitor {

    static let fnKeyCode: CGKeyCode = 63
    static var accessibilityPermissionChecker: () -> Bool = {
        AXIsProcessTrusted()
    }
    /// Prompts for permission - should only be called from explicit user action
    static var accessibilityPermissionRequester: () -> Void = {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    /// Opens System Settings to Accessibility preferences
    static func openSystemSettingsAccessibility() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    var onStartRecording: (() -> Void)?
    var onStopRecording: (() -> Void)?

    var targetKeyCode: CGKeyCode = 63
    var targetModifierFlags: UInt = 0

    private var eventTap: CFMachPort?
    fileprivate var isShortcutPressed: Bool = false
    private var runLoopSource: CFRunLoopSource?

    static func checkAccessibilityPermission() -> Bool {
        accessibilityPermissionChecker()
    }

    static func requestAccessibilityPermission() {
        accessibilityPermissionRequester()
    }

    @discardableResult
    func start() -> Bool {
        stop()

        let eventsOfInterest: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventsOfInterest,
            callback: globalEventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            Logger.event.error("Failed to create event tap. Ensure Accessibility permissions are granted.")
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
        Logger.event.info("Event tap started")
        return true
    }

    func updateTargetShortcut(keyCode: CGKeyCode, modifierFlags: UInt) {
        let wasRunning = eventTap != nil
        stop()
        targetKeyCode = keyCode
        targetModifierFlags = modifierFlags
        if wasRunning {
            _ = start()
        }
        Logger.settings.info("Updated shortcut to keyCode: \(keyCode), modifiers: \(modifierFlags)")
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }

        eventTap = nil
        isShortcutPressed = false
        runLoopSource = nil
    }
}

private func globalEventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let monitor = Unmanaged<GlobalEventMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = UInt(event.flags.rawValue & UInt64(NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue))

    let isTargetKey = keyCode == monitor.targetKeyCode
    let isModifierMatch = flags == monitor.targetModifierFlags

    switch type {
    case .keyDown:
        if isTargetKey && isModifierMatch {
            monitor.onStartRecording?()
            return nil
        }

    case .keyUp:
        if isTargetKey && isModifierMatch {
            monitor.onStopRecording?()
            return nil
        }

    case .flagsChanged:
        if monitor.targetKeyCode == 63 {
            let isPressed = event.flags.contains(.maskSecondaryFn)
            if isPressed, !monitor.isShortcutPressed {
                monitor.isShortcutPressed = true
                monitor.onStartRecording?()
                return nil
            }
            if !isPressed, monitor.isShortcutPressed {
                monitor.isShortcutPressed = false
                monitor.onStopRecording?()
                return nil
            }
        }

    default:
        break
    }

    return Unmanaged.passUnretained(event)
}
