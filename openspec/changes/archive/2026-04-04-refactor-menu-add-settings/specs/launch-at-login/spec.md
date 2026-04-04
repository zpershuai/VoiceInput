## ADDED Requirements

### Requirement: Launch at login toggle in Settings
The system SHALL provide a toggle switch in Settings to enable/disable "Launch at Login".

#### Scenario: Enable launch at login
- **GIVEN** user is in Settings window
- **WHEN** user enables the "Launch at Login" toggle
- **THEN** the system registers the app to start automatically on login
- **AND** the toggle reflects the enabled state

#### Scenario: Disable launch at login
- **GIVEN** user is in Settings window
- **WHEN** user disables the "Launch at Login" toggle
- **THEN** the system unregisters the app from automatic startup
- **AND** the toggle reflects the disabled state

### Requirement: Launch at login state persistence
The system SHALL remember the launch-at-login setting across app restarts.

#### Scenario: Setting persists after restart
- **GIVEN** user has enabled "Launch at Login"
- **WHEN** app is closed and reopened
- **THEN** the toggle shows the previously selected state

### Requirement: Permission handling for launch at login
The system SHALL handle cases where the user has not granted necessary permissions for launch-at-login.

#### Scenario: Permission not granted
- **GIVEN** user tries to enable "Launch at Login"
- **WHEN** the system lacks required permissions
- **THEN** the system shows a helpful message guiding the user to System Settings
- **AND** the toggle remains in the disabled state
