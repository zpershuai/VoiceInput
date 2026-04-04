## ADDED Requirements

### Requirement: Settings window uses compact top spacing
The system SHALL present the Settings window with compact top spacing so the first section begins close to the title bar instead of leaving excessive empty space.

#### Scenario: General section appears near top
- **WHEN** the user opens the Settings window
- **THEN** the `General` section is visible near the top of the content area
- **AND** the window does not show a large unused blank region above the first section

### Requirement: Bottom action buttons remain fully visible
The system SHALL keep the Settings window action buttons fully visible within the default window size.

#### Scenario: Test and Save buttons are fully rendered
- **WHEN** the user opens the Settings window with LLM settings enabled
- **THEN** the `Test` and `Save` buttons are fully visible within the window bounds
- **AND** both buttons remain clickable without resizing the window

### Requirement: Settings sections keep a clean vertical rhythm
The system SHALL maintain clear but restrained spacing between sections and controls so the window appears elegant and simple without changing its information hierarchy.

#### Scenario: Sections remain readable after spacing adjustments
- **WHEN** the user scans the Settings window
- **THEN** each section header is visually associated with its controls
- **AND** adjacent sections remain distinct without oversized gaps
