import Foundation

final class ShortcutManager {
    static let shared = ShortcutManager()
    
    private init() {}
    
    var currentShortcut: Shortcut? {
        get {
            Shortcut.loadFromUserDefaults()
        }
        set {
            if let shortcut = newValue {
                shortcut.saveToUserDefaults()
            } else {
                Shortcut.clearFromUserDefaults()
            }
        }
    }
    
    var effectiveShortcut: Shortcut {
        currentShortcut ?? .default
    }
    
    func resetToDefault() {
        Shortcut.clearFromUserDefaults()
    }
    
    func saveShortcut(_ shortcut: Shortcut) {
        shortcut.saveToUserDefaults()
    }
}
