## 1. Extend GlobalEventMonitor with Permission API

- [x] 1.1 Add `checkAccessibilityPermission()` static method to GlobalEventMonitor
- [x] 1.2 Add `requestAccessibilityPermission()` static method to GlobalEventMonitor
- [x] 1.3 Import ApplicationServices framework in GlobalEventMonitor.swift
- [x] 1.4 Test permission check returns correct boolean value

## 2. Create Permission Alert Dialog Component

- [x] 2.1 Create new file `PermissionAlert.swift` in Sources/VoiceInput/
- [x] 2.2 Implement `showAccessibilityPermissionAlert()` function
- [x] 2.3 Add Chinese and English localized strings for dialog
- [x] 2.4 Implement "Open System Settings" button action
- [x] 2.5 Implement "Quit" button action

## 3. Implement Permission Polling Mechanism

- [x] 3.1 Add timer-based polling in PermissionAlert
- [x] 3.2 Detect permission granted state change
- [x] 3.3 Auto-dismiss dialog when permission granted
- [x] 3.4 Stop polling appropriately (permission granted or dialog dismissed)

## 4. Integrate Permission Check in AppDelegate

- [x] 4.1 Modify `applicationDidFinishLaunching()` to check permission before starting monitor
- [x] 4.2 Show permission alert if permission not granted
- [x] 4.3 Start GlobalEventMonitor automatically when permission detected
- [x] 4.4 Handle app launch flow when permission already granted

## 5. Testing and Verification

- [x] 5.1 Test app with permission already granted (normal flow)
- [x] 5.2 Test app without permission (dialog appears)
- [x] 5.3 Test "Open System Settings" button navigates correctly
- [x] 5.4 Test auto-detection when permission granted in System Settings
- [x] 5.5 Test dialog dismissal when clicking "Quit"
- [x] 5.6 Verify event monitor starts automatically after permission granted

## 6. Documentation

- [x] 6.1 Update README.md with permission requirement explanation
- [x] 6.2 Add CHANGELOG entry for this feature
