## Why

Users report that the text displayed in the floating capsule sometimes does not match the text ultimately pasted into the target application. The current logs are insufficient to trace the full lifecycle of a recording session—from partial/final speech recognitions, through optional LLM refinement, to final text injection. We need structured, session-scoped debug logging to pinpoint where discrepancies are introduced.

## What Changes

- Introduce a per-recording `sessionId` (UUID) to correlate all logs within a single voice-input session.
- Extend `SpeechRecognizer` to log every partial/final transcription with length and timestamp, and to log which transcription path (`finalTranscription` vs `lastTranscription`) is returned on stop.
- Extend `AppDelegate` to log captured text, LLM refine before/after comparison, and the active frontmost application / focused element before injection.
- Extend `TextInjector` to log the full received text, length, timestamp, and injection success/failure.
- Add a new `session-debug-logging` capability spec to document these traceability requirements.

## Capabilities

### New Capabilities
- `session-debug-logging`: Structured per-session debug logs that trace speech recognition results, LLM refinement deltas, and text injection outcomes to diagnose text mismatches between the capsule and the clipboard.

### Modified Capabilities
- *(none — no existing spec-level behavior changes)*

## Impact

- `Sources/VoiceInput/SpeechRecognizer.swift` — add session-aware logging in partial/final/stop paths.
- `Sources/VoiceInput/AppDelegate.swift` — pass `sessionId` through the pipeline, log LLM deltas and frontmost app info.
- `Sources/VoiceInput/TextInjector.swift` — log injection payload and result.
- `Sources/VoiceInput/Logger.swift` — optionally add a helper for session-scoped log prefixes.
- No public API or user-facing behavior changes; purely additive debugging instrumentation.
