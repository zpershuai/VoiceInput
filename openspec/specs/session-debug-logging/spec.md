## Purpose

Define the debug logging requirements needed to trace a complete voice-input session—from speech recognition through optional LLM refinement to final text injection—so that mismatches between the floating capsule text and the injected text can be diagnosed from logs alone.

## Requirements

### Requirement: Session correlation identifier
Every voice-input session SHALL be assigned a unique `sessionId` that appears in all related log lines for that session.

#### Scenario: Session start
- **WHEN** the user begins a recording
- **THEN** the system generates a `sessionId` and includes it in every subsequent log line for speech recognition, refinement, and injection

### Requirement: Speech recognition traceability
The system SHALL log every partial and final transcription result with its full text, character length, and timestamp.

#### Scenario: Partial result received
- **WHEN** the speech recognizer emits a partial transcription
- **THEN** the log includes the partial text, its length, and a timestamp

#### Scenario: Final result received
- **WHEN** the speech recognizer emits a final transcription
- **THEN** the log includes the final text, its length, and a timestamp

#### Scenario: Recording stopped
- **WHEN** `stopRecording()` is called
- **THEN** the log records the stop timestamp and whether the returned transcription came from `finalTranscription` or `lastTranscription`

### Requirement: LLM refinement traceability
When LLM refinement is enabled, the system SHALL log the original text, the refined text, and whether they differ.

#### Scenario: Refinement succeeds
- **WHEN** LLM refinement is enabled and returns a result
- **THEN** the log includes the original text length, refined text length, and a flag indicating if the text changed

#### Scenario: Refinement fails
- **WHEN** LLM refinement is enabled but throws an error
- **THEN** the log records the failure and notes that the original text will be injected as fallback

### Requirement: Text injection traceability
The system SHALL log the complete text payload sent to `TextInjector`, the frontmost application information, and the injection success or failure.

#### Scenario: Injection requested
- **WHEN** `TextInjector.inject()` is called
- **THEN** the log includes the injected text, its length, a timestamp, the frontmost application bundle identifier, and the focused element role/title if available

#### Scenario: Injection completes
- **WHEN** text injection finishes
- **THEN** the log records whether the injection succeeded or failed
