# Documentation System

## ADDED Requirements

### Requirement: Repository documentation SHALL provide layered navigation
The repository SHALL provide a layered documentation entry structure in which `README.md` serves as the top-level project entry point and `docs/README.md` serves as the deep documentation index. The two entry points MUST have distinct responsibilities and MUST direct readers to the correct next document based on their goal.

#### Scenario: Reader starts from the repository root
- **WHEN** a reader opens `README.md`
- **THEN** the document presents the project purpose, quick-start usage, a concise summary of the runtime workflow, and links to deeper documents
- **AND** it does not attempt to inline the full architecture, troubleshooting, and maintenance details that belong in `docs/`

#### Scenario: Reader needs deeper technical documentation
- **WHEN** a reader follows documentation links from `README.md` or opens `docs/README.md`
- **THEN** the documentation index groups deep content by technical goal such as architecture understanding, development, troubleshooting, and reference lookup
- **AND** the index makes it clear which document to read next for each goal

### Requirement: Documentation SHALL describe the end-to-end runtime workflow
The documentation system SHALL describe the actual end-to-end VoiceInput runtime workflow as implemented in the current codebase, including initialization, permission handling, shortcut monitoring, recording, speech recognition, optional LLM refinement, and text injection.

#### Scenario: Maintainer studies the main runtime flow
- **WHEN** a maintainer reads the workflow documentation
- **THEN** the document explains the ordered control flow from application launch through text injection completion
- **AND** it identifies the primary modules, callbacks, and state transitions involved in each stage

#### Scenario: Maintainer compares documentation against source modules
- **WHEN** a maintainer cross-checks the workflow documentation with the current source files
- **THEN** the documented stages map to concrete modules in `Sources/VoiceInput/`
- **AND** the workflow description avoids stale interfaces or superseded behavior

### Requirement: Documentation SHALL explain module boundaries and data flow
The documentation system SHALL explain each core module's responsibility, upstream and downstream dependencies, and the flow of key runtime data including audio buffers, transcription text, refined text, user settings, permissions state, and log signals.

#### Scenario: Maintainer investigates module interactions
- **WHEN** a maintainer reads the architecture or module documentation
- **THEN** the document identifies how core modules collaborate and which module owns each major responsibility
- **AND** it distinguishes control flow from data flow where they differ

#### Scenario: Maintainer traces important runtime data
- **WHEN** a maintainer needs to understand how recognition results or settings move through the app
- **THEN** the documentation shows where that data originates, where it is transformed, and where it is consumed
- **AND** it names the module boundaries crossed during that path

### Requirement: Documentation SHALL provide actionable troubleshooting paths
The documentation system SHALL provide troubleshooting guidance that maps user-visible symptoms to likely failure layers, relevant permissions or external dependencies, source modules to inspect, and log modules or signals to verify.

#### Scenario: Maintainer diagnoses a recording startup failure
- **WHEN** a maintainer investigates a symptom such as shortcut press with no recording start
- **THEN** the troubleshooting guidance points to the relevant permission checks, event monitoring path, and associated log modules
- **AND** it provides a repeatable sequence for isolating whether the failure is in startup, permission, input monitoring, or recording setup

#### Scenario: Maintainer diagnoses a post-recognition failure
- **WHEN** a maintainer investigates a symptom such as recognized text not being refined or injected
- **THEN** the troubleshooting guidance identifies the relevant downstream modules and decision branches
- **AND** it explains which log outputs or configuration states should be checked first

### Requirement: Documentation SHALL define maintenance expectations
The documentation system SHALL define explicit maintenance rules so that future feature or behavior changes update the appropriate documentation layers instead of leaving the entry documents and deep documents inconsistent.

#### Scenario: New feature changes user-facing capability
- **WHEN** a future change adds or changes a user-visible capability
- **THEN** the documentation maintenance rules require updates to the appropriate entry and deep documents
- **AND** the rules identify which documentation layers are expected to change

#### Scenario: Core runtime behavior changes
- **WHEN** a future change alters the runtime workflow, module interaction, logging surface, or troubleshooting path
- **THEN** the maintenance rules require updates to the affected workflow, architecture, or troubleshooting documents
- **AND** the documentation system continues to reflect the current implementation
