import Foundation
import CoreGraphics

final class GlobalEventMonitor {

    static let fnKeyCode: CGKeyCode = 63

    var onStartRecording: (() -> Void)?
    var onStopRecording: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() {
        stop()

        let eventsOfInterest: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

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

    default:
        return Unmanaged.passUnretained(event)
    }
}
