## Context

VoiceInput currently performs two launch-time actions when Accessibility permission is missing:

1. `AppDelegate.handleAccessibilityPermissionAtLaunch()` calls `GlobalEventMonitor.requestAccessibilityPermission()`, which invokes `AXIsProcessTrustedWithOptions` with `kAXTrustedCheckOptionPrompt = true`.
2. The app immediately shows `PermissionAlert`, a custom blocking modal that also tells the user to open System Settings.

That guarantees two concurrent UX surfaces for the same problem: the system-managed Accessibility prompt and the app-managed permission window.

The second issue appears after rebuild and reinstall. The current install flow creates a fresh app bundle in `build/release`, signs it ad hoc (`codesign --sign -`), and copies it into `/Applications` via `cp -R`. For macOS TCC, Accessibility trust is not just a display name check. It is evaluated against the installed app identity and code requirement. Replacing the bundle with a differently signed binary can cause the existing trust record to stop matching, which is why users end up deleting the old entry and granting permission again.

## Goals / Non-Goals

**Goals:**
- Ensure launch-time permission guidance is driven by a single app-controlled window.
- Avoid triggering the system Accessibility prompt automatically during normal launch.
- Make the `/Applications/VoiceInput.app` installation path stable enough that a normal rebuild/install cycle does not repeatedly invalidate existing Accessibility trust.
- Improve logging so it is clear whether failure came from missing permission, identity drift, or event tap startup.

**Non-Goals:**
- Bypassing macOS TCC or auto-granting Accessibility permission.
- Guaranteeing trust persistence for arbitrary unsigned or ad hoc developer builds outside the supported install flow.
- Changing unrelated permission types such as microphone or speech recognition.

## Decisions

### Decision 1: Split permission status checks from permission prompting
**Choice:** Keep `checkAccessibilityPermission()` as a pure status read, and replace the current automatic prompt call with an explicit user-initiated API used only from the permission window action.

**Rationale:**
- `AXIsProcessTrusted()` is sufficient for launch-time detection without side effects.
- `AXIsProcessTrustedWithOptions(... prompt: true)` directly causes the system dialog. If it runs on launch, a single-window UX is impossible.
- Explicit prompting after the user clicks the custom window aligns the UX with the user's expectation and avoids immediate duplicate surfaces.

**Alternatives considered:**
- Keep the current automatic prompt and merely delay the custom window: still produces two permission surfaces and races with the app modal.
- Remove all system prompting entirely and only deep-link to System Settings: workable, but less robust if Apple changes deep-link behavior. The explicit action can still choose whether to open settings directly or ask macOS to foreground the permission pane.

### Decision 2: Make the app-controlled window the only launch-time permission UI
**Choice:** On missing permission, show `PermissionAlert` only. The primary button becomes the single place that may open System Settings and, if needed, request the system prompt.

**Rationale:**
- The app already has a localized blocking flow with polling and auto-resume.
- A single permission window eliminates duplicate instructions and user confusion.
- The button click is a natural point to log intent and prevent repeated prompt attempts while the modal is visible.

**Alternatives considered:**
- Use only the system prompt: insufficient because the app still needs localized explanation and retry/polling behavior.
- Make the custom window non-blocking: weaker guidance for a core feature and easier to ignore.

### Decision 3: Treat stable Accessibility trust as an installation contract, not just runtime logic
**Choice:** Introduce a supported install flow for `/Applications` that preserves a stable app identity, and make repeated ad hoc overwrite installs an unsupported path for trust persistence.

**Rationale:**
- TCC persistence depends on a stable designated requirement. Re-signing every build ad hoc can produce an identity macOS no longer considers the same trusted app.
- The app cannot repair this in runtime code; the build/install pipeline must cooperate.
- An explicit install contract makes the behavior diagnosable and prevents the false assumption that any copied debug build should keep Accessibility trust.

**Implementation direction:**
- Prefer a configured, stable signing identity for app bundles intended for `/Applications`.
- Make `make install` replace the target bundle in a controlled way and log the signing identity used.
- If no stable signing identity is configured, fail fast or warn clearly that trust persistence is not guaranteed for that install.

**Alternatives considered:**
- Continue ad hoc signing and attempt runtime workarounds: cannot make TCC reuse an invalidated trust record.
- Key the solution only on bundle identifier: insufficient because TCC checks more than bundle ID.

### Decision 4: Add focused diagnostics for trust drift
**Choice:** Log the launch path, bundle identifier, executable path, permission status, whether prompting was user initiated, and the result of event tap startup.

**Rationale:**
- The current log only shows “missing permission” and “failed to create event tap,” which hides whether the app was reinstalled under a different identity.
- Permission regressions are hard to verify without a single launch trace.

**Alternatives considered:**
- No extra logging: keeps the root cause opaque the next time this regresses.

## Risks / Trade-offs

- `[Stable signing identity unavailable in some developer environments]` → Make the supported `/Applications` install path explicit and fail or warn loudly instead of pretending trust persistence will work.
- `[System Settings deep link behavior changes across macOS releases]` → Keep the custom window as the source of truth and isolate the settings-opening logic behind one action.
- `[Polling may continue after a failed prompt attempt]` → Tie polling lifecycle strictly to the modal lifecycle and log every transition.
- `[Users may still manually drag in an unsupported build]` → Document the supported install path and surface that status in logs.

## Migration Plan

1. Update runtime code so launch checks permission without prompting and shows only the custom permission window.
2. Route the permission window button through a single method that opens System Settings and optionally triggers the system prompt only after user action.
3. Update the build/install flow to require or prefer a stable signing identity for `/Applications` installs, and emit diagnostics about the installed signature.
4. Manually verify three paths:
   - Existing trusted install launches with no permission UI.
   - First-time install shows only the custom window, then resumes automatically after permission is granted.
   - Rebuild/reinstall over an already trusted `/Applications` app does not require deleting the old Accessibility entry when using the supported install flow.

## Open Questions

- Should unsupported ad hoc installs into `/Applications` hard-fail, or just print a warning and leave responsibility to the developer?
- Do we want the permission button to call the system prompt API at all, or only deep-link to the Accessibility settings pane?
