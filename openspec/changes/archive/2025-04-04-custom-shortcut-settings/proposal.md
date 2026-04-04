## Why

Currently, VoiceInput uses the hardcoded Fn key (keyCode 63) as the only trigger for voice recording. Users have requested the ability to customize this shortcut to better fit their workflow and avoid conflicts with other applications that may also use the Fn key. This change will make the app more flexible and user-friendly.

## What Changes

- Add a new "Keyboard Shortcut" section in SettingsWindow with a shortcut recorder UI
- Create ShortcutManager to handle custom shortcut persistence and management
- Modify GlobalEventMonitor to support dynamic key code configuration
- Store shortcut preferences in UserDefaults with proper serialization
- Support any key combination (single keys like Fn, or modified keys like ⌘+Space)
- Maintain backward compatibility: default to Fn key if no custom shortcut is set

## Capabilities

### New Capabilities
- `custom-shortcut`: User-configurable keyboard shortcut for triggering voice recording, including shortcut capture UI, persistence, and dynamic registration

### Modified Capabilities
- None (GlobalEventMonitor modification is implementation detail; the external API remains unchanged)

## Impact

- **SettingsWindow.swift**: Add new UI section for shortcut configuration
- **GlobalEventMonitor.swift**: Support configurable keyCode instead of hardcoded 63
- **New ShortcutManager.swift**: Manage shortcut persistence and validation
- **UserDefaults**: New keys for storing shortcut configuration
- **No breaking changes**: Existing Fn key behavior remains the default
