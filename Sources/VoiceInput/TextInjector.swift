import Foundation
import AppKit
import CoreGraphics

final class TextInjector {

    static func inject(text: String, completion: ((Bool) -> Void)?) {
        guard !text.isEmpty else {
            DispatchQueue.main.async { completion?(false) }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let pasteSucceeded = Self.performInjection(text: text)
            DispatchQueue.main.async {
                completion?(pasteSucceeded)
            }
        }
    }

    private static func performInjection(text: String) -> Bool {
        let result = DispatchQueue.main.sync { () -> Bool in
            Logger.input.info("Starting text injection (\(text.count) chars)")

            let typingSucceeded = simulateTyping(text)
            Logger.input.debug("Unicode typing result: \(typingSucceeded)")
            return typingSucceeded
        }

        return result
    }

    private static func simulateTyping(_ text: String) -> Bool {
        let utf16 = Array(text.utf16)
        guard !utf16.isEmpty else { return false }

        guard let keyDown = CGEvent(
            keyboardEventSource: nil,
            virtualKey: 0,
            keyDown: true
        ) else {
            return false
        }

        guard let keyUp = CGEvent(
            keyboardEventSource: nil,
            virtualKey: 0,
            keyDown: false
        ) else {
            return false
        }

        keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)

        keyDown.post(tap: .cgSessionEventTap)
        usleep(12_000)
        keyUp.post(tap: .cgSessionEventTap)

        return true
    }
}
