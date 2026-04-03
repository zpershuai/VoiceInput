## Why

The LLM Refinement Settings window contains three text input fields (API Base URL, API Key, Model), but they do not respond to standard macOS keyboard shortcuts for text editing (Cmd+C, Cmd+V, Cmd+X). This is a significant usability issue as users expect to be able to copy/paste API URLs and keys from other applications. The bug occurs because the custom window implementation lacks proper menu action support for text fields.

## What Changes

- Fix `SettingsWindow.swift` to enable standard macOS text editing shortcuts (Copy, Paste, Cut, Select All) in all text fields
- Ensure both `NSTextField` and `NSSecureTextField` properly handle menu actions
- No breaking changes to existing functionality or UI appearance

## Capabilities

### New Capabilities
<!-- No new capabilities introduced - this is a bug fix -->

### Modified Capabilities
<!-- This is a bug fix that doesn't change spec-level behavior -->

## Impact

- **File**: `Sources/VoiceInput/SettingsWindow.swift`
- **Component**: Settings window text input fields
- **User Impact**: Restores expected macOS text editing behavior
- **Risk**: Low - isolated to SettingsWindow, no API or data model changes
