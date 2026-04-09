import Foundation
import AppKit
import CoreGraphics

final class TextInjector {

    static func inject(text: String, sessionId: String? = nil, completion: ((Bool) -> Void)?) {
        guard !text.isEmpty else {
            Logger.input.warning("TextInjector received empty text, skipping injection", sessionId: sessionId)
            DispatchQueue.main.async { completion?(false) }
            return
        }

        Logger.input.info("TextInjector received text (\(text.count) chars): \(text)", sessionId: sessionId)

        DispatchQueue.global(qos: .userInitiated).async {
            let pasteSucceeded = Self.performInjection(text: text, sessionId: sessionId)
            DispatchQueue.main.async {
                if pasteSucceeded {
                    Logger.input.info("Text injection successful", sessionId: sessionId)
                } else {
                    Logger.input.error("Text injection failed", sessionId: sessionId)
                }
                completion?(pasteSucceeded)
            }
        }
    }

    private static func performInjection(text: String, sessionId: String?) -> Bool {
        let result = DispatchQueue.main.sync { () -> Bool in
            Logger.input.info("Starting text injection (\(text.count) chars): \(text)", sessionId: sessionId)
            let typingSucceeded = simulateTyping(text)
            Logger.input.debug("Unicode typing result: \(typingSucceeded)", sessionId: sessionId)
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
