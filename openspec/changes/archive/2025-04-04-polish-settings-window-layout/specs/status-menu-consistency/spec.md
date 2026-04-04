## ADDED Requirements

### Requirement: Settings menu item matches peer item style
The system SHALL display the `Settings...` status bar menu item using the same plain text style as other top-level menu items such as `Language` and `Quit`.

#### Scenario: Settings item has no leading icon
- **WHEN** the user opens the status bar menu
- **THEN** the `Settings...` item appears without a leading icon
- **AND** its label style is visually consistent with adjacent top-level menu items
