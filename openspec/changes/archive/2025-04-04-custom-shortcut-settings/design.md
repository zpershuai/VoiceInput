## Context

VoiceInput currently uses a hardcoded Fn key (keyCode 63) to trigger voice recording via CoreGraphics event taps. The GlobalEventMonitor creates a CGEvent tap that listens for keyDown/keyUp/flagsChanged events specifically for the Fn key. Users want flexibility to choose their own shortcut.

Current architecture:
- GlobalEventMonitor: Hardcoded `static let fnKeyCode: CGKeyCode = 63`
- SettingsWindow: Has LLM settings and launch-at-login, no shortcut configuration
- UserDefaults pattern: Used by LanguageManager, LLMRefiner, LaunchAtLoginManager

## Goals / Non-Goals

**Goals:**
- Allow users to customize the recording trigger shortcut
- Provide intuitive UI for capturing new shortcuts (click to record, press keys)
- Persist shortcut configuration across app restarts
- Support modifier key combinations (⌘, ⌥, ⇧, ⌃) + any key
- Maintain Fn key as default for backward compatibility
- Gracefully handle shortcut conflicts and invalid inputs

**Non-Goals:**
- Multiple shortcut profiles or per-app shortcuts
- System-wide shortcuts when app is not running
- Complex shortcut conflict resolution UI
- Supporting mouse buttons or gestures
- Changing the underlying event tap mechanism (CGEvent.tapCreate still used)

## Decisions

### Decision 1: Data Model for Shortcut Storage

**Choice:** Store shortcut as a Codable struct with `keyCode` (UInt16) and `modifierFlags` (UInt).

```swift
struct Shortcut: Codable, Equatable {
    let keyCode: UInt16
    let modifierFlags: UInt
}
```

**Rationale:** 
- NSEvent.ModifierFlags is OptionSet and stores as raw UInt value
- Codable enables easy UserDefaults serialization via JSON
- Keeps data model simple and platform-native

**Alternatives considered:**
- String representation (e.g., "⌘+Space") — harder to parse, prone to localization issues
- Separate Bool flags for each modifier — more verbose, harder to extend

### Decision 2: Shortcut Recording UI Pattern

**Choice:** Create a dedicated ShortcutRecorderView NSView subclass with "Click to Record" → "Press shortcut..." → display captured shortcut flow.

**Rationale:**
- Consistent with macOS standard apps (System Settings, etc.)
- Clear user feedback during recording state
- Can validate and reject invalid shortcuts in real-time

**Implementation approach:**
- NSButton subclass or custom NSView with NSTextField
- Local NSEvent monitor during recording mode
- Visual feedback: pulsing border or text change during recording

### Decision 3: Persistence Strategy

**Choice:** Use UserDefaults with JSON-encoded Shortcut struct, following existing app patterns.

```swift
// In ShortcutManager
static var currentShortcut: Shortcut? {
    get {
        guard let data = UserDefaults.standard.data(forKey: shortcutKey) else {
            return nil // Returns nil, caller uses default
        }
        return try? JSONDecoder().decode(Shortcut.self, from: data)
    }
    set {
        if let shortcut = newValue,
           let data = try? JSONEncoder().encode(shortcut) {
            UserDefaults.standard.set(data, forKey: shortcutKey)
        } else {
            UserDefaults.standard.removeObject(forKey: shortcutKey)
        }
    }
}
```

**Rationale:**
- Consistent with existing LanguageManager, LLMRefiner patterns
- Simple, no external dependencies needed
- Atomic storage (single key for entire shortcut config)

### Decision 4: GlobalEventMonitor Modification Strategy

**Choice:** Add instance property `targetKeyCode: CGKeyCode` with default value 63, and method to update it dynamically.

```swift
final class GlobalEventMonitor {
    var targetKeyCode: CGKeyCode = 63  // Default to Fn
    
    func updateTargetKeyCode(_ keyCode: CGKeyCode) {
        stop()
        targetKeyCode = keyCode
        start()
    }
}
```

**Rationale:**
- Minimal changes to existing code
- Event tap must be recreated when changing monitored key
- Preserves all existing callback and permission logic

### Decision 5: Modifier Key Support

**Choice:** Store modifier flags alongside keyCode and check them in the event tap callback.

**Implementation in globalEventTapCallback:**
```swift
let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
let flags = event.flags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue

// Check if key matches AND modifiers match
if keyCode == monitor.targetKeyCode && flags == monitor.targetModifierFlags {
    // Handle start/stop
}
```

**Rationale:**
- Enables complex shortcuts like ⌘+Space, ⌃+R
- Requires checking flagsChanged for modifier-only state
- More flexible than single-key shortcuts

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| [Risk] User sets shortcut that conflicts with system shortcut | Display warning in UI; allow override; provide "Reset to Default" button |
| [Risk] Accessibility permission not granted when changing shortcut | Shortcut change succeeds but shows warning; monitor starts when permission granted |
| [Risk] Invalid key combination captured (e.g., just modifier keys) | Validate in recorder: require non-modifier key; reject if only modifiers pressed |
| [Risk] App doesn't respond to new shortcut immediately | GlobalEventMonitor.stop()/.start() cycle ensures fresh event tap with new key |
| [Risk] User forgets their custom shortcut | Show current shortcut in menu bar tooltip; provide "Reset" in settings |
| [Trade-off] CGEvent tap recreation is brief window where no shortcuts work | Acceptable: happens only during settings change, < 100ms downtime |

## Migration Plan

1. **New install**: Default to Fn key (no stored shortcut = use default)
2. **Existing users**: Continue using Fn key until they explicitly change in settings
3. **Rollback**: Remove UserDefaults key `recordingShortcut` to revert to Fn key default

## Open Questions

1. Should we validate against common system shortcuts (⌘+Space for Spotlight) and warn users?
2. Should Escape key always cancel recording mode, or can it be set as the shortcut?
3. Do we need a "Test shortcut" button in settings?
