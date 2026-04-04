import AppKit
import Foundation

struct Shortcut: Codable, Equatable {
    let keyCode: UInt16
    let modifierFlags: UInt
    
    static let `default` = Shortcut(keyCode: 63, modifierFlags: 0)
    
    private static let storageKey = "recordingShortcut"
    
    var isDefault: Bool {
        return keyCode == 63 && modifierFlags == 0
    }
    
    func toData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
    
    static func from(data: Data) -> Shortcut? {
        return try? JSONDecoder().decode(Shortcut.self, from: data)
    }
    
    static func loadFromUserDefaults() -> Shortcut? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return nil
        }
        return Shortcut.from(data: data)
    }
    
    func saveToUserDefaults() {
        if let data = toData() {
            UserDefaults.standard.set(data, forKey: Shortcut.storageKey)
        }
    }
    
    static func clearFromUserDefaults() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

// MARK: - Display Formatting

extension Shortcut {
    var displayString: String {
        var result = ""
        let flags = NSEvent.ModifierFlags(rawValue: modifierFlags)
        
        if flags.contains(.control) {
            result += "⌃"
        }
        if flags.contains(.option) {
            result += "⌥"
        }
        if flags.contains(.shift) {
            result += "⇧"
        }
        if flags.contains(.command) {
            result += "⌘"
        }
        
        result += keyDisplayName
        
        return result
    }
    
    private var keyDisplayName: String {
        switch keyCode {
        case 36: return "↩"
        case 48: return "⇥"
        case 49: return "Space"
        case 51: return "⌫"
        case 53: return "⎋"
        case 55: return "⌘"
        case 56: return "⇧"
        case 57: return "⇪"
        case 58: return "⌥"
        case 59: return "⌃"
        case 60: return "⇧"
        case 61: return "⌥"
        case 62: return "⌃"
        case 63: return "Fn"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 99: return "F3"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 111: return "F12"
        case 118: return "F4"
        case 120: return "F2"
        case 122: return "F1"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default:
            if let char = keyCodeToCharacter(keyCode) {
                return char.uppercased()
            }
            return "Key(\(keyCode))"
        }
    }
    
    private func keyCodeToCharacter(_ code: UInt16) -> String? {
        let keyMap: [UInt16: String] = [
            0: "a", 1: "s", 2: "d", 3: "f", 4: "h",
            5: "g", 6: "z", 7: "x", 8: "c", 9: "v",
            11: "b", 12: "q", 13: "w", 14: "e", 15: "r",
            16: "y", 17: "t", 18: "1", 19: "2", 20: "3",
            21: "4", 22: "6", 23: "5", 24: "=", 25: "9",
            26: "7", 27: "-", 28: "8", 29: "0", 30: "]",
            31: "o", 32: "u", 33: "[", 34: "i", 35: "p",
            37: "l", 38: "j", 39: "'", 40: "k", 41: ";",
            42: "\\", 43: ",", 44: "/", 45: "n", 46: "m",
            47: ".", 50: "`"
        ]
        return keyMap[code]
    }
}

extension NSEvent {
    var shortcut: Shortcut? {
        guard type == .keyDown else { return nil }
        let deviceIndependentFlags = modifierFlags.intersection(.deviceIndependentFlagsMask)
        return Shortcut(keyCode: keyCode, modifierFlags: deviceIndependentFlags.rawValue)
    }
}
