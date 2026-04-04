## MODIFIED Requirements

### Requirement: LLM configuration moved to Settings window
The system SHALL provide LLM configuration within the Settings window instead of a separate submenu.

**Previous behavior**: LLM had a dedicated submenu in the status bar with "Enable Refinement" toggle and "Settings..." option to open LLM configuration window.

**New behavior**: LLM configuration is a section within the unified Settings window, accessible via the main "Settings..." menu item.

#### Scenario: LLM settings in unified Settings window
- **WHEN** user opens Settings
- **THEN** the Settings window displays an "LLM Refinement" section
- **AND** the section contains:
  - An "Enable LLM Refinement" checkbox
  - API Base URL text field
  - API Key secure text field
  - Model text field
  - Test and Save buttons

#### Scenario: LLM submenu removed from status bar
- **WHEN** user clicks the status bar icon
- **THEN** the menu does NOT show "LLM Refinement" as a submenu
- **AND** instead shows "Settings..." as a direct menu item

### Requirement: LLM enable toggle location changed
The system SHALL move the "Enable LLM Refinement" toggle from the status bar menu to the Settings window.

**Previous behavior**: "Enable Refinement" was a checkbox in the status bar submenu, toggling LLM on/off without opening a window.

**New behavior**: "Enable LLM Refinement" is a checkbox within the LLM section of the Settings window.

#### Scenario: Enable LLM from Settings
- **GIVEN** user has opened Settings
- **WHEN** user checks the "Enable LLM Refinement" checkbox
- **THEN** LLM refinement becomes active for subsequent voice inputs
- **AND** the setting persists across app restarts

#### Scenario: Disable LLM from Settings
- **GIVEN** user has opened Settings
- **WHEN** user unchecks the "Enable LLM Refinement" checkbox
- **THEN** LLM refinement becomes inactive
- **AND** voice input text is injected without LLM processing

## REMOVED Requirements

### Requirement: LLM Refinement status bar submenu
**Reason**: Consolidated into unified Settings window for better UX consistency
**Migration**: Use the main "Settings..." menu item to access LLM configuration
