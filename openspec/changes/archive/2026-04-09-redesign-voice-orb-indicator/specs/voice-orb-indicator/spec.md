## ADDED Requirements

### Requirement: Recording indicator renders as a single circular orb
The system SHALL render the floating-window recording indicator as one visually circular orb instead of a five-bar waveform meter.

#### Scenario: Idle indicator shows one orb
- **WHEN** the floating recording window is visible
- **AND** the current audio energy is near zero
- **THEN** the indicator SHALL appear as a single circular orb
- **AND** it SHALL NOT render a row of five vertical bars or equivalent discrete meter elements

#### Scenario: Orb silhouette remains stable
- **WHEN** live RMS input changes during recording
- **THEN** the indicator SHALL preserve a visually circular outer silhouette
- **AND** any pulse or scale animation SHALL remain subtle enough that the control still reads as one stable orb

### Requirement: Orb remains visually alive while idle
The system SHALL keep the orb in a calm animated listening state even when live RMS input is minimal.

#### Scenario: Idle state retains soft motion
- **WHEN** the recording window is visible
- **AND** RMS remains within the idle range
- **THEN** the orb SHALL retain visible low-intensity internal motion
- **AND** its dominant color family SHALL remain in cool blue or blue-cyan tones

### Requirement: Orb color responds continuously to speaking intensity
The system SHALL map live RMS intensity to a cool-to-hot color transition so louder speech appears visually hotter than quieter speech.

#### Scenario: Moderate speech warms the orb
- **WHEN** RMS rises above the idle range into an active speaking range
- **THEN** the orb SHALL shift away from pure blue toward warmer intermediate hues
- **AND** the transition SHALL occur smoothly rather than as an abrupt binary color switch

#### Scenario: Loud speech introduces hot accents
- **WHEN** RMS reaches a high-energy speaking range
- **THEN** the orb SHALL display clearly warmer accents in the red or orange-red family
- **AND** those hot accents SHALL be more pronounced than in lower RMS ranges

### Requirement: Orb motion intensity responds continuously to speaking intensity
The system SHALL increase the orb's visual energy as RMS rises by adjusting internal motion, glow, or pulse intensity.

#### Scenario: Quiet speech stays restrained
- **WHEN** RMS is above idle but still relatively low
- **THEN** the orb SHALL show more motion than the idle state
- **AND** the visual response SHALL remain restrained compared with louder speech

#### Scenario: Loud speech strengthens pulse and glow
- **WHEN** RMS rises into a high-energy range
- **THEN** the orb SHALL show stronger internal motion and brighter glow than in lower RMS ranges
- **AND** any pulse animation SHALL remain coordinated with the orb rather than breaking its shape

### Requirement: Orb remains integrated with the floating capsule layout
The system SHALL preserve the integrated floating-window layout while accommodating the orb as a near-circular left-side indicator.

#### Scenario: Orb stays centered in single-line layout
- **WHEN** the floating capsule is shown in its default or expanded single-line state
- **THEN** the orb SHALL remain vertically centered within the left indicator area
- **AND** it SHALL remain visually balanced with the transcript text block

#### Scenario: Orb stays centered in two-line layout
- **WHEN** the floating capsule enters the two-line transcript state
- **THEN** the orb SHALL remain vertically centered relative to the overall capsule content
- **AND** the orb SHALL continue to read as a circular indicator rather than appearing vertically compressed
