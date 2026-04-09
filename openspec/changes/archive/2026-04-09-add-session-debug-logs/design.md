## Context

VoiceInput currently logs events in an ad-hoc manner (e.g., `Logger.speech.debug("Partial result: \(text)")`). When users report that the floating capsule text differs from the injected text, it is difficult to correlate logs across `SpeechRecognizer`, `AppDelegate`, and `TextInjector`. There is no session-scoped identifier, lengths are not consistently logged, and the frontmost application context at injection time is not captured.

## Goals / Non-Goals

**Goals:**
- Provide a single `sessionId` that ties together all log lines for one voice-input session.
- Make it possible to diff `partial` → `final` → `refined` → `injected` text lengths and contents from logs alone.
- Log the frontmost application and focused accessibility element before injection to rule out target-app issues.
- Keep changes additive and low-risk—no behavior changes to speech recognition, LLM logic, or injection mechanics.

**Non-Goals:**
- Building a persistent telemetry or analytics pipeline.
- Changing log rotation or storage format.
- Modifying the UI/UX of the floating window.

## Decisions

1. **Session ID as `UUID` string passed explicitly**
   - *Rationale*: `UUID` is collision-resistant and requires no state management. We generate it in `startRecording()` and pass it through the async pipeline rather than storing it globally, avoiding concurrency issues if two recordings overlap.
   - *Alternative considered*: A global `currentSessionId` variable. Rejected because it complicates reasoning about async boundaries.

2. **Log lengths alongside truncated content**
   - *Rationale*: Chinese and mixed scripts can make prefix truncation misleading. Logging `count` ensures we can detect subtle truncation or encoding issues.

3. **Use `NSWorkspace.shared.frontmostApplication` and `AXUIElementCopyAttributeValue` for frontmost app info**
   - *Rationale*: Available without new entitlements on macOS 14+. Gives bundle ID and focused element role/title, which helps identify whether the target app changed between recognition and injection.

4. **Keep `SpeechRecognizer` agnostic of `sessionId`**
   - *Rationale*: `SpeechRecognizer` is a reusable component. It should not depend on a voice-input session concept. `AppDelegate` will annotate logs with `sessionId` based on callbacks.
   - *Exception*: We may optionally pass `sessionId` into `stopRecording()` solely for the stop/flush log context if the caller wants to log the returned value with that ID.

## Risks / Trade-offs

- **[Risk]** AX API calls on the background queue can be slow or fail if accessibility permissions are revoked at runtime.
  - *Mitigation*: Wrap AX queries in a short timeout (or `try?`) and log failure gracefully without blocking injection.
- **[Risk]** Extra logging adds negligible I/O but could theoretically jitter timing-sensitive events.
  - *Mitigation*: Log on the same queue where work already happens (no extra thread hops). Use string interpolation that Swift optimizes well.

## Migration Plan

No migration needed. This is a pure instrumentation change. Users will see additional context in the existing log file at `~/Library/Logs/VoiceInput/` after the next build.
