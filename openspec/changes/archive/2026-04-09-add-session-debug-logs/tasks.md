## 1. Logger enhancements

- [x] 1.1 Add a `sessionId` parameter overload or helper to `Logger` so log lines can include a session prefix (e.g., `[session:<id>]`)
- [x] 1.2 Verify `Logger.swift` compiles after changes

## 2. SpeechRecognizer debug logs

- [x] 2.1 In `SpeechRecognizer.startRecording()`, log the start of a new recording session
- [x] 2.2 In the recognition task callback, log every `partial` result with full text, `count`, and timestamp
- [x] 2.3 In the recognition task callback, log every `final` result with full text, `count`, and timestamp
- [x] 2.4 In `stopRecording()`, log when it is called with a timestamp
- [x] 2.5 In `flushStopIfNeeded()`, log whether the returned value comes from `finalTranscription` or `lastTranscription`, including the text and `count`

## 3. AppDelegate session plumbing and debug logs

- [x] 3.1 Generate a `sessionId` (UUID string) at the beginning of `startRecording()` and store it in an instance property
- [x] 3.2 Include `sessionId` in all `SpeechRecognizer` callback logs (`onPartialResult`, `onFinalResult`, `onError`)
- [x] 3.3 In `stopRecordingAndInject()`, log the captured text with its full content, `count`, and `sessionId`
- [x] 3.4 When LLM refinement is enabled, log the original text and refined text lengths, and whether they are equal or different
- [x] 3.5 When LLM refinement fails, log the failure and fallback decision with `sessionId`
- [x] 3.6 Before calling `injectText()`, capture and log the current frontmost application bundle identifier and focused accessibility element info (role/title) using `NSWorkspace` and `AXUIElement`
- [x] 3.7 Pass `sessionId` into `TextInjector.inject()` or correlate the injection log back to the session

## 4. TextInjector debug logs

- [x] 4.1 In `TextInjector.inject()`, log the complete received text, its `count`, and timestamp on entry
- [x] 4.2 In the injection completion handler, log `success` or `failure` with the `sessionId`
- [x] 4.3 If `performInjection()` returns early (empty text), log the early return reason

## 5. Verification

- [x] 5.1 Build the project with `swift build` and fix any compilation errors
- [x] 5.2 Review the log output format to ensure all session-scoped lines are easily greppable by `sessionId`
- [x] 5.3 Do a quick mental walkthrough of a full recording → partial → final → inject flow to confirm no log gap exists
