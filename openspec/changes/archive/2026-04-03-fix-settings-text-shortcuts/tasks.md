## 1. Fix Text Editing Shortcuts in SettingsWindow

- [x] 1.1 Read current SettingsWindow.swift implementation to understand text field setup
- [x] 1.2 Add `validateUserInterfaceItem(_:)` method to SettingsWindow to enable copy/paste/cut/selectAll actions
- [x] 1.3 Add `copy:`, `paste:`, `cut:`, `selectAll:` action methods that forward to first responder
- [x] 1.4 Build and verify the fix compiles without errors
- [x] 1.5 Test Cmd+C, Cmd+V, Cmd+X, Cmd+A in all three text fields (API URL, API Key, Model)
