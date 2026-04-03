## Context

VoiceInput currently initializes the `GlobalEventMonitor` in `AppDelegate.applicationDidFinishLaunching()` without checking if Accessibility permissions are granted. The `CGEvent.tapCreate()` call fails silently, logging only an error message. Users experience the app as "not working" without understanding why.

Current flow:
```
App Launch → Init GlobalEventMonitor → CGEvent.tapCreate() fails → Log error → App continues (broken)
```

The macOS Accessibility permission system requires:
1. App requests permission via API
2. User grants permission in System Settings → Privacy & Security → Accessibility
3. Permission persists until explicitly revoked
4. Permission can be checked programmatically via `AXIsProcessTrustedWithOptions`

## Goals / Non-Goals

**Goals:**
- Detect missing Accessibility permissions at startup
- Display a blocking modal dialog explaining the requirement
- Provide direct navigation to System Settings
- Poll for permission changes and auto-enable when granted
- Clear, actionable messaging in both English and Chinese (matching app's language support)

**Non-Goals:**
- Automatic permission granting (impossible on macOS)
- Complex permission workflows for other permission types
- Fallback behavior without permissions (Fn key monitoring is core functionality)

## Decisions

### Decision 1: Blocking Modal Dialog vs Menu Bar Indicator
**Choice:** Blocking modal dialog with "Open System Settings" button

**Rationale:**
- Accessibility permission is required for core functionality (Fn key monitoring)
- Without it, the app is essentially non-functional
- A blocking dialog forces immediate resolution
- Menu bar indicator would be easy to miss

**Alternatives considered:**
- Menu bar icon with warning badge: Too subtle, users might not notice
- Non-blocking notification: Same issue - easy to ignore

### Decision 2: Permission Polling Strategy
**Choice:** 1-second interval polling while dialog is visible

**Rationale:**
- macOS doesn't provide a callback when permissions change
- Polling is the only way to detect user action
- 1-second interval is responsive without being resource-intensive
- Polling stops when permission granted or dialog dismissed

**Implementation:**
```swift
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    if AXIsProcessTrustedWithOptions(...) {
        // Enable event monitor
        // Dismiss dialog
    }
}
```

### Decision 3: Dialog Design
**Choice:** Native NSAlert with custom styling to match VoiceInput aesthetic

**Rationale:**
- Native alerts respect system appearance (light/dark mode)
- Simple API, consistent with macOS patterns
- Can add "Don't show again" checkbox if needed later

**Dialog content:**
- Title: "需要辅助功能权限" / "Accessibility Permission Required"
- Message: Explanation that Fn key monitoring requires permission
- Buttons: [打开系统设置] [退出] / [Open System Settings] [Quit]

### Decision 4: Permission Check API Location
**Choice:** Extend `GlobalEventMonitor` with static method

**Rationale:**
- Keeps permission logic co-located with the code that needs it
- `GlobalEventMonitor` already imports Carbon and CoreGraphics
- Clean separation: monitor knows how to check, delegate decides what to do

```swift
extension GlobalEventMonitor {
    static func checkAccessibilityPermission() -> Bool
    static func requestAccessibilityPermission()
}
```

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| User doesn't understand why permission is needed | Clear, jargon-free explanation in dialog |
| User clicks "Open System Settings" but doesn't actually add the app | Polling detects permission and enables automatically when granted |
| Dialog appears repeatedly if user dismisses without granting | Currently acceptable - app is non-functional without permission |
| Sandbox restrictions prevent opening System Settings | Use `NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)` |
| App signed with different certificate than when permission granted | Permission is tied to bundle ID, not certificate - works across builds |

## Migration Plan

Not applicable - this is purely additive functionality with no migration needed.

## Open Questions

None - implementation approach is clear.
