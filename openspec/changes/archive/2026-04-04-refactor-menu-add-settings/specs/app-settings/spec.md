## ADDED Requirements

### Requirement: Settings menu item in status bar
The system SHALL provide a "Settings..." menu item in the status bar menu.

#### Scenario: User opens Settings from menu bar
- **WHEN** user clicks the status bar icon
- **THEN** the menu displays "Settings..." option
- **AND** clicking it opens the Settings window

### Requirement: Settings window with multiple sections
The system SHALL display a Settings window with organized sections for different configuration categories.

#### Scenario: Settings window layout
- **WHEN** user opens Settings
- **THEN** a window titled "Settings" appears
- **AND** the window contains a "General" section with launch-at-login option
- **AND** the window contains an "LLM Refinement" section with configuration options
- **AND** sections are visually separated

### Requirement: Settings persist across app restarts
The system SHALL persist all settings to UserDefaults and restore them on app launch.

#### Scenario: Settings persistence
- **GIVEN** user has configured settings
- **WHEN** app is restarted
- **THEN** all settings are restored to their previous values

### Requirement: Keyboard shortcut for Settings
The system SHALL support standard keyboard shortcut to open Settings.

#### Scenario: Keyboard shortcut opens Settings
- **WHEN** user presses ⌘,
- **THEN** the Settings window opens
