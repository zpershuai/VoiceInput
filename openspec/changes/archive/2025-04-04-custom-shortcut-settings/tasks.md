## 1. Data Model & Persistence

- [x] 1.1 Create `Shortcut.swift` with Shortcut struct (keyCode: UInt16, modifierFlags: UInt) conforming to Codable and Equatable
- [x] 1.2 Create `ShortcutManager.swift` with UserDefaults read/write methods for shortcut persistence
- [x] 1.3 Add computed property `currentShortcut` that returns nil (default) or stored shortcut
- [x] 1.4 Add `resetToDefault()` method to clear stored shortcut

## 2. GlobalEventMonitor Enhancement

- [x] 2.1 Add `targetKeyCode: CGKeyCode` instance property with default value 63
- [x] 2.2 Add `targetModifierFlags: UInt` instance property with default value 0
- [x] 2.3 Modify `globalEventTapCallback` to check both keyCode AND modifierFlags match
- [x] 2.4 Add `updateTargetShortcut(_:)` method that stops, updates properties, and restarts event tap
- [x] 2.5 Update callback logic to handle flagsChanged for modifier state detection

## 3. Shortcut Recorder UI Component

- [x] 3.1 Create `ShortcutRecorderView.swift` NSView subclass for shortcut capture
- [x] 3.2 Add `isRecording` state with visual feedback (pulsing border or text change)
- [x] 3.3 Implement click-to-enter-recording-mode behavior
- [x] 3.4 Add local NSEvent monitor to capture keyDown events during recording
- [x] 3.5 Implement validation: reject modifier-only input, accept valid combinations
- [x] 3.6 Handle Escape key to cancel recording without changes
- [x] 3.7 Add shortcut display formatting with macOS symbols (⌘⌥⇧⌃)

## 4. SettingsWindow Integration

- [x] 4.1 Add keyboard shortcut section in `buildContent()` after General section
- [x] 4.2 Add separator between General and Keyboard Shortcut sections
- [x] 4.3 Add "Keyboard Shortcut" label with bold font styling
- [x] 4.4 Add ShortcutRecorderView instance to the section
- [x] 4.5 Add "Reset to Default" button next to recorder
- [x] 4.6 Update window height from 320 to accommodate new section (~400)
- [x] 4.7 Load current shortcut in `show()` method and update recorder display

## 5. AppDelegate Integration

- [x] 5.1 Import ShortcutManager in AppDelegate
- [x] 5.2 Initialize GlobalEventMonitor with stored shortcut on launch
- [x] 5.3 Add method to reload shortcut configuration when settings change
- [x] 5.4 Connect ShortcutManager changes to GlobalEventMonitor.updateTargetShortcut()

## 6. Testing & Validation

- [x] 6.1 Test Fn key still works as default when no custom shortcut set
- [x] 6.2 Test setting custom shortcut (e.g., ⌘+Space) and verify it triggers recording
- [x] 6.3 Test shortcut persists across app restarts
- [x] 6.4 Test "Reset to Default" clears custom shortcut and reverts to Fn key
- [x] 6.5 Test modifier-only input is rejected in recording mode
- [x] 6.6 Test Escape key cancels recording mode without changes
- [x] 6.7 Test settings window displays current shortcut correctly on open
