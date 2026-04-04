## ADDED Requirements

### Requirement: Shortcut data model
The system SHALL define a Shortcut struct that stores keyCode and modifierFlags for keyboard shortcuts.

#### Scenario: Valid shortcut creation
- **WHEN** a user presses ⌘+Space
- **THEN** the system creates a Shortcut with keyCode=49 and modifierFlags containing .command

#### Scenario: Default shortcut fallback
- **WHEN** no custom shortcut is stored in UserDefaults
- **THEN** the system uses the default Fn key (keyCode=63) with no modifiers

### Requirement: Shortcut persistence
The system SHALL persist custom shortcuts in UserDefaults using JSON encoding.

#### Scenario: Save custom shortcut
- **WHEN** user sets a new shortcut in settings
- **THEN** the system serializes the Shortcut struct to JSON and stores it in UserDefaults key "recordingShortcut"

#### Scenario: Load stored shortcut
- **WHEN** the app launches
- **THEN** the system reads UserDefaults key "recordingShortcut" and deserializes it to a Shortcut struct

#### Scenario: Clear custom shortcut
- **WHEN** user clicks "Reset to Default" or clears the shortcut
- **THEN** the system removes the "recordingShortcut" key from UserDefaults

### Requirement: Shortcut recording UI
The system SHALL provide a UI component that captures keyboard input when the user wants to set a new shortcut.

#### Scenario: Enter recording mode
- **WHEN** user clicks the shortcut recorder in Settings
- **THEN** the UI enters recording mode showing "Press shortcut..."

#### Scenario: Capture valid shortcut
- **GIVEN** the UI is in recording mode
- **WHEN** user presses a valid key combination (non-modifier key with optional modifiers)
- **THEN** the UI exits recording mode and displays the captured shortcut (e.g., "⌘+Space")

#### Scenario: Cancel recording with Escape
- **GIVEN** the UI is in recording mode
- **WHEN** user presses Escape
- **THEN** the UI exits recording mode without saving changes

#### Scenario: Reject modifier-only input
- **GIVEN** the UI is in recording mode
- **WHEN** user presses only modifier keys (⌘, ⌥, ⇧, ⌃) without a regular key
- **THEN** the input is ignored and recording mode continues

### Requirement: Dynamic shortcut registration
The system SHALL update the GlobalEventMonitor to use the configured shortcut instead of hardcoded Fn key.

#### Scenario: Apply new shortcut immediately
- **GIVEN** user sets a new shortcut in Settings
- **WHEN** user saves the settings
- **THEN** the GlobalEventMonitor stops, updates the target key code, and restarts with the new shortcut

#### Scenario: Use stored shortcut on launch
- **GIVEN** a custom shortcut was previously saved
- **WHEN** the app launches
- **THEN** GlobalEventMonitor initializes with the stored shortcut instead of default Fn key

#### Scenario: Fallback to default shortcut
- **GIVEN** no custom shortcut is stored
- **WHEN** the app launches
- **THEN** GlobalEventMonitor initializes with the default Fn key (keyCode=63)

### Requirement: Shortcut display formatting
The system SHALL display shortcuts using standard macOS modifier symbols (⌘, ⌥, ⇧, ⌃).

#### Scenario: Display modifier combination
- **GIVEN** a shortcut with keyCode=49 (Space) and modifiers [.command, .shift]
- **WHEN** displaying in the UI
- **THEN** it shows as "⇧⌘Space"

#### Scenario: Display single key
- **GIVEN** a shortcut with keyCode=63 (Fn) and no modifiers
- **WHEN** displaying in the UI
- **THEN** it shows as "Fn"

### Requirement: Settings window integration
The system SHALL add a Keyboard Shortcut section in SettingsWindow between General and LLM Refinement sections.

#### Scenario: Show current shortcut
- **GIVEN** user opens Settings
- **WHEN** the settings window displays
- **THEN** a "Keyboard Shortcut" section shows the currently configured shortcut (or "Fn" if using default)

#### Scenario: Shortcut section layout
- **GIVEN** user opens Settings
- **WHEN** viewing the settings window
- **THEN** the Keyboard Shortcut section appears after General section with a separator

### Requirement: Reset to default
The system SHALL provide a way for users to reset the shortcut to the default Fn key.

#### Scenario: Reset shortcut
- **GIVEN** user has set a custom shortcut
- **WHEN** user clicks "Reset to Default" button
- **THEN** the custom shortcut is cleared from UserDefaults and the UI shows "Fn"
