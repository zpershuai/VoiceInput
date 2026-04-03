## ADDED Requirements

### Requirement: Floating window renders as a single capsule surface
The system SHALL render the voice input floating window as one visible capsule-shaped surface without exposing a separate square or rectangular background panel behind it.

#### Scenario: Initial presentation frame is visually aligned
- **WHEN** the floating window is shown for the first time
- **THEN** the visible window shape SHALL appear as a capsule from the first rendered frame
- **AND** no detached square or rectangular translucent base SHALL be visible behind it

#### Scenario: Animated entry preserves single-surface appearance
- **WHEN** the floating window performs its entry animation
- **THEN** the animation SHALL scale and fade a single capsule surface
- **AND** the waveform and text SHALL remain visually contained inside that capsule during the animation

### Requirement: Floating window uses a default single-line layout
The system SHALL present the floating window with a default width for short content and keep the waveform and text vertically centered as one integrated row.

#### Scenario: Short text remains in default capsule
- **WHEN** the displayed text fits within the default text width
- **THEN** the floating window SHALL remain at its default capsule width
- **AND** the waveform SHALL remain vertically centered within the capsule
- **AND** the text block SHALL remain vertically centered within the capsule

### Requirement: Floating window grows horizontally before becoming multi-line
The system SHALL expand the capsule width before increasing its height when displayed text exceeds the default single-line width.

#### Scenario: Medium-length text widens the capsule
- **WHEN** the displayed text exceeds the default single-line width
- **AND** the text still fits within the maximum single-line width
- **THEN** the floating window SHALL increase its width smoothly
- **AND** the layout SHALL remain a single centered row

### Requirement: Floating window supports a centered two-line capsule state
The system SHALL switch to a taller capsule that supports at most two lines after the width cap is reached, while preserving the integrated alignment between waveform and text.

#### Scenario: Long text enters two-line mode
- **WHEN** the displayed text exceeds the maximum single-line width
- **THEN** the floating window SHALL keep its maximum width
- **AND** it SHALL increase height to display up to two lines inside the same capsule
- **AND** the waveform SHALL remain vertically centered relative to the two-line text block
- **AND** the text block SHALL remain vertically centered within the capsule

#### Scenario: Text overflow stays contained inside the capsule
- **WHEN** the displayed text exceeds the capacity of the two-line capsule
- **THEN** the system SHALL truncate the visible text within the capsule
- **AND** it SHALL NOT render detached overflow indicators or a separate lower row outside the integrated text block

### Requirement: Size transitions remain spatially stable
The system SHALL keep the floating window anchored consistently while resizing between default, widened, and two-line states.

#### Scenario: Width change remains centered on screen
- **WHEN** the floating window changes width
- **THEN** it SHALL remain horizontally centered relative to the screen position used for the floating transcription UI

#### Scenario: Height change does not reveal a background panel
- **WHEN** the floating window changes from single-line to two-line mode
- **THEN** the visible shape SHALL remain one capsule surface
- **AND** the transition SHALL NOT reveal a differently shaped backing view
