## Why

VoiceInput currently treats missing Accessibility permission as two separate launch actions: it triggers the macOS system prompt and immediately shows a custom blocking window. After rebuilding and copying the app into `/Applications`, the app is also frequently treated as a newly authorized binary, forcing the user to remove the old entry and grant permission again. This makes the permission flow noisy and unreliable for a core feature.

## What Changes

- Remove the automatic system Accessibility prompt from the normal launch path and rely on a single custom permission window as the primary user-facing guidance.
- Add explicit rules for when the app may open System Settings so permission guidance happens only after the user clicks the custom window's action.
- Stabilize the installed app identity used for Accessibility permission checks so replacing the app bundle in `/Applications` does not require repeated manual cleanup in System Settings during normal rebuild/install cycles.
- Update logging around permission detection, permission prompting, and event tap startup so repeated authorization failures can be diagnosed from one launch log.

## Capabilities

### New Capabilities
- `stable-app-installation`: Ensure the installed `/Applications/VoiceInput.app` keeps a stable identity across normal rebuild/install cycles so persisted macOS trust records remain usable.

### Modified Capabilities
- `accessibility-permission-check`: Change the permission flow so launch shows only the app-controlled permission window, defers the System Settings jump until explicit user action, and resumes monitoring automatically once permission becomes valid.

## Impact

- Affected code: `Sources/VoiceInput/AppDelegate.swift`, `Sources/VoiceInput/GlobalEventMonitor.swift`, `Sources/VoiceInput/PermissionAlert.swift`, and build/install logic such as `Makefile`
- Affected systems: macOS TCC Accessibility trust, app bundle installation in `/Applications`, launch-time permission UX
- No external dependencies expected, but code-signing/install behavior may need to change to preserve a stable app identity
