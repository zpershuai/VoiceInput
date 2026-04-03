import ApplicationServices
import CoreGraphics
import Foundation

final class GlobalEventMonitor {

    static let fnKeyCode: CGKeyCode = 63
    static var accessibilityPermissionChecker: () -> Bool = {
        AXIsProcessTrusted()
    }
    static var accessibilityPermissionRequester: () -> Void = {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    var onStartRecording: (() -> Void)?
    var onStopRecording: (() -> Void)?

    private var eventTap: CFMachPort?
    fileprivate var isFnPressed: Bool = false
    private var runLoopSource: CFRunLoopSource?

    static func checkAccessibilityPermission() -> Bool {
        accessibilityPermissionChecker()
    }

    static func requestAccessibilityPermission() {
        accessibilityPermissionRequester()
    }

    func start() {
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
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }

        eventTap = nil
        isFnPressed = false
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

    guard keyCode == GlobalEventMonitor.fnKeyCode else {
        return Unmanaged.passUnretained(event)
    }

    switch type {
    case .keyDown:
        monitor.onStartRecording?()
        return nil

    case .keyUp:
        monitor.onStopRecording?()
        return nil

    case .flagsChanged:
        let isPressed = event.flags.contains(.maskSecondaryFn)

        if isPressed, !monitor.isFnPressed {
            monitor.isFnPressed = true
            monitor.onStartRecording?()
            return nil
        }

        if !isPressed, monitor.isFnPressed {
            monitor.isFnPressed = false
            monitor.onStopRecording?()
            return nil
        }

        return Unmanaged.passUnretained(event)

    default:
        return Unmanaged.passUnretained(event)
    }
}
