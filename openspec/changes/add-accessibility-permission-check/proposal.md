## Why

VoiceInput requires macOS Accessibility permissions to globally monitor the Fn key for voice input triggering. Currently, when permissions are not granted, the app silently fails with only a log message, leaving users confused about why the app doesn't work. We need to proactively detect missing permissions and guide users through the authorization process with a clear, blocking UI dialog.

## What Changes

- Add Accessibility permission detection at app startup
- Display a modal dialog when permissions are missing, blocking further app functionality
- Provide a "Open System Settings" button that directly navigates to Accessibility preferences
- Implement permission status polling to detect when user has granted permission
- Automatically enable the event monitor once permission is granted
- Add permission checking utilities to `GlobalEventMonitor`

## Capabilities

### New Capabilities
- `accessibility-permission-check`: Detect missing Accessibility permissions and guide users through authorization with a blocking modal dialog

### Modified Capabilities
<!-- No existing capabilities modified - this is purely additive functionality -->

## Impact

- **AppDelegate.swift**: Modified to check permissions before starting event monitor
- **GlobalEventMonitor.swift**: Extended with permission checking API
- **New file**: Permission alert UI component (modal dialog)
- **Info.plist**: May need accessibility usage description string
- User experience: App will show blocking dialog until permission granted
