## Context

The LLM Refinement Settings window in VoiceInput uses a custom `NSWindow` with programmatically created text fields. The current implementation creates `NSTextField` and `NSSecureTextField` instances directly without connecting them to the responder chain's standard editing actions. On macOS, text editing shortcuts (Cmd+C/V/X/A) are handled through the `NSResponder` protocol's action methods (`copy:`, `paste:`, `cut:`, `selectAll:`), which are typically routed through the main menu. When a window lacks proper menu support or the first responder doesn't handle these actions, the shortcuts fail silently.

## Goals / Non-Goals

**Goals:**
- Enable Cmd+C (Copy), Cmd+V (Paste), Cmd+X (Cut), and Cmd+A (Select All) in all Settings window text fields
- Maintain existing UI appearance and behavior
- Follow macOS standard patterns for text field editing

**Non-Goals:**
- Adding a full menu bar to the Settings window
- Changing the window appearance or layout
- Adding additional keyboard shortcuts beyond standard text editing
- Modifying other windows or components

## Decisions

**Decision**: Override `validateUserInterfaceItem` and implement action methods in `SettingsWindow`

**Rationale**: The minimal fix is to ensure the window's responder chain properly handles standard editing actions. The `NSWindow` (or its delegate) can implement `validateUserInterfaceItem(_:)` to enable/disable menu items and action methods (`copy:`, `paste:`, `cut:`, `selectAll:`) to forward them to the first responder (the active text field). This is the standard macOS pattern and requires minimal code changes.

**Alternative considered**: Adding an `NSMenu` to the window
- Rejected: Overkill for a simple settings dialog; would add unnecessary complexity and UI elements

**Alternative considered**: Subclassing `NSTextField` to handle actions
- Rejected: Would require replacing all existing field instances; the window-level solution is cleaner

## Risks / Trade-offs

- **[Risk]** The fix might inadvertently enable other menu actions that shouldn't be available
  - **Mitigation**: Only validate and enable the specific editing actions we need (copy:, paste:, cut:, selectAll:)

- **[Risk]** Secure text field (API Key) might have different paste behavior expectations
  - **Mitigation**: `NSSecureTextField` inherits from `NSTextField` and handles paste internally; our forwarding is transparent
