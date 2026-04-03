import Foundation
import AppKit
import Carbon
import CoreGraphics

final class TextInjector {

    private static let cjkKeywords = [
        "zh", "ja", "ko",
        "Chinese", "Japanese", "Korean",
        "Pinyin", "Wubi",
        "Hiragana", "Katakana"
    ]

    private static let asciiKeyboardSourceID = "com.apple.keylayout.US"

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
            
            let savedClipboard = NSPasteboard.general.string(forType: .string)
            Logger.input.debug("Saved clipboard content")

            let currentInputSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
            let currentSourceID = sourceID(from: currentInputSource)
            Logger.input.debug("Current input source: \(currentSourceID ?? "unknown")")

            var switchedToAscii = false

            if isCJKInputSource(sourceID: currentSourceID) {
                Logger.input.info("Detected CJK input method, switching to ASCII")
                if let asciiSource = findAsciiInputSource() {
                    let status = TISSelectInputSource(asciiSource)
                    if status == noErr {
                        switchedToAscii = true
                        usleep(50_000)
                        Logger.input.debug("Switched to ASCII input method")
                    } else {
                        Logger.input.warning("Failed to switch to ASCII input method (status: \(status))")
                    }
                } else {
                    Logger.input.warning("Could not find ASCII input source")
                }
            }

            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            Logger.input.debug("Set clipboard content")

            let pasteSucceeded = simulateCmdV()
            Logger.input.debug("Paste simulation result: \(pasteSucceeded)")

            usleep(100_000)

            if let saved = savedClipboard {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(saved, forType: .string)
                Logger.input.debug("Restored original clipboard")
            }

            if switchedToAscii {
                TISSelectInputSource(currentInputSource)
                Logger.input.debug("Restored original input method")
            }

            return pasteSucceeded
        }

        return result
    }

    private static func isCJKInputSource(sourceID: String?) -> Bool {
        guard let sourceID else { return false }
        return cjkKeywords.contains { sourceID.contains($0) }
    }

    private static func sourceID(from source: TISInputSource) -> String? {
        let cfValue = TISGetInputSourceProperty(source, kTISPropertyInputSourceID)
        return unsafeBitCast(cfValue, to: CFString?.self) as String?
    }

    private static func findAsciiInputSource() -> TISInputSource? {
        let property = [kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource]
        guard let sourceList = TISCreateInputSourceList(property as CFDictionary, false).takeRetainedValue() as? [TISInputSource] else {
            return nil
        }

        for source in sourceList {
            if let sourceID = sourceID(from: source),
               sourceID == asciiKeyboardSourceID {
                return source
            }
        }

        for source in sourceList {
            if let sourceID = sourceID(from: source),
               sourceID.contains("ABC") || sourceID.contains("US") {
                return source
            }
        }

        return nil
    }

    private static func simulateCmdV() -> Bool {
        guard let vKeyDown = CGEvent(
            keyboardEventSource: nil,
            virtualKey: 0x09,
            keyDown: true
        ) else { return false }

        vKeyDown.flags = .maskCommand

        guard let vKeyUp = CGEvent(
            keyboardEventSource: nil,
            virtualKey: 0x09,
            keyDown: false
        ) else { return false }

        vKeyUp.flags = .maskCommand

        vKeyDown.post(tap: .cgSessionEventTap)
        usleep(50_000)
        vKeyUp.post(tap: .cgSessionEventTap)

        return true
    }
}
