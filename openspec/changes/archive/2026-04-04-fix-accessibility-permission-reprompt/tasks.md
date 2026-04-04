## 1. Launch-Time Permission Flow

- [x] 1.1 Refactor `GlobalEventMonitor` so permission status checks do not trigger the system Accessibility prompt during app launch.
- [x] 1.2 Update `AppDelegate.handleAccessibilityPermissionAtLaunch()` to show only the app-controlled permission window when Accessibility permission is missing.
- [x] 1.3 Change `PermissionAlert` so its primary action is the only path that opens System Settings or triggers any user-initiated system prompt behavior.
- [x] 1.4 Add launch-time logging for permission status, prompt source, and event monitor startup outcome.

## 2. Stable Installation Identity

- [x] 2.1 Update the build/install flow to support a stable signing identity for `/Applications/VoiceInput.app` installs used with Accessibility permission.
- [x] 2.2 Replace the current app bundle copy/install step with a controlled macOS app-bundle installation approach and print install identity diagnostics.
- [x] 2.3 Fail fast or emit a clear warning when the supported install flow cannot guarantee permission persistence across reinstalls.

## 3. Verification

- [x] 3.1 Manually verify that a first launch without Accessibility permission shows only the custom permission window.
- [x] 3.2 Manually verify that granting permission from System Settings dismisses the custom window and starts the event monitor automatically.
- [x] 3.3 Manually verify that reinstalling a previously trusted `/Applications` build via the supported install flow does not require deleting and re-adding the Accessibility entry.

(End of file - total 18 lines)
