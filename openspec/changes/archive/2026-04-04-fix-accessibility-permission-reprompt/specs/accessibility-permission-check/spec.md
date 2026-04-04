## MODIFIED Requirements

### Requirement: Detect missing Accessibility permissions at startup
The system SHALL check Accessibility permission status during application initialization before attempting to create the event tap, and this launch-time check SHALL NOT trigger the macOS system Accessibility prompt automatically.

#### Scenario: Permission already granted
- **WHEN** the application launches
- **AND** Accessibility permission has been previously granted
- **THEN** the application proceeds to start the GlobalEventMonitor normally
- **AND** no permission dialog is displayed

#### Scenario: Permission not granted
- **WHEN** the application launches
- **AND** Accessibility permission has not been granted
- **THEN** a blocking app-controlled modal dialog SHALL be displayed
- **AND** the GlobalEventMonitor SHALL NOT attempt to create event tap
- **AND** the launch-time permission check SHALL NOT trigger a separate macOS system Accessibility prompt

### Requirement: Display blocking permission dialog
The system SHALL display a single blocking modal dialog explaining the Accessibility permission requirement when permissions are missing.

#### Scenario: Dialog content
- **WHEN** the permission dialog is displayed
- **THEN** it SHALL include a title explaining the requirement
- **AND** it SHALL include descriptive text explaining why the permission is needed
- **AND** it SHALL include an "Open System Settings" button
- **AND** it SHALL include a "Quit" button

#### Scenario: Dialog matches app language
- **WHEN** the permission dialog is displayed
- **AND** the app language is set to Chinese
- **THEN** the dialog SHALL display Chinese text
- **WHEN** the app language is set to English
- **THEN** the dialog SHALL display English text

#### Scenario: Only one permission window is shown
- **WHEN** the permission dialog is displayed because launch-time Accessibility permission is missing
- **THEN** the user SHALL see only the app-controlled permission window
- **AND** the app SHALL NOT concurrently display a separate system-triggered Accessibility prompt unless the user explicitly requests it from the dialog

### Requirement: Navigate to System Settings
The system SHALL open System Settings to the Accessibility preferences only after explicit user action from the permission dialog.

#### Scenario: Open System Settings
- **WHEN** the user clicks the "Open System Settings" button
- **THEN** the system SHALL open System Settings
- **AND** it SHALL navigate directly to Privacy & Security → Accessibility

#### Scenario: No automatic settings navigation at launch
- **WHEN** the application launches without Accessibility permission
- **THEN** the system SHALL wait for the user to click the permission dialog action before opening System Settings

### Requirement: Poll for permission changes
The system SHALL periodically check for permission status changes while the dialog is displayed.

#### Scenario: Permission granted while dialog visible
- **WHEN** the permission dialog is displayed
- **AND** the user grants Accessibility permission in System Settings
- **THEN** the system SHALL detect the permission change within 1 second
- **AND** the dialog SHALL automatically dismiss
- **AND** the GlobalEventMonitor SHALL start automatically

#### Scenario: Polling stops appropriately
- **WHEN** the permission is granted
- **THEN** polling SHALL stop
- **WHEN** the user clicks "Quit"
- **THEN** polling SHALL stop
- **AND** the application SHALL terminate

### Requirement: Provide permission check API
The system SHALL provide separate programmatic APIs to check Accessibility permission status and to perform any user-initiated permission prompt action.

#### Scenario: Check permission status
- **WHEN** calling `GlobalEventMonitor.checkAccessibilityPermission()`
- **THEN** it SHALL return `true` if permission is granted
- **AND** it SHALL return `false` if permission is not granted
- **AND** it SHALL NOT trigger a system Accessibility prompt

#### Scenario: Request permission from explicit user action
- **WHEN** calling the permission prompt API from the permission dialog's user action
- **THEN** it MAY trigger the system permission prompt
- **AND** it SHALL return immediately (non-blocking)
- **AND** it SHALL NOT be called automatically during launch initialization
